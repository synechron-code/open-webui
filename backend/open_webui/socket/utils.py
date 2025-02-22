import base64
import json
import redis
import uuid
import logging

from open_webui.env import (
    ENABLE_AZURE_AUTHENTICATION,
    SRC_LOG_LEVELS
)

log = logging.getLogger(__name__)
log.setLevel(SRC_LOG_LEVELS["SOCKET"])

class RedisService:
    _instance = None

    def __new__(cls, redis_url, ssl_ca_certs=None, username=None, password=None):
        if cls._instance is None:
            cls._instance = super(RedisService, cls).__new__(cls)
            cls._instance._initialize(redis_url, ssl_ca_certs, username, password)
        return cls._instance

    def _initialize(self, redis_url, ssl_ca_certs=None, username=None, password=None):
        if not password and ENABLE_AZURE_AUTHENTICATION:
            from azure.identity import DefaultAzureCredential
            cred = DefaultAzureCredential()
            token = cred.get_token("https://redis.azure.com/.default")
            password = token.token
            username = self.extract_username_from_token(password)

        try:
            masked_password = f"{password[:3]}***{password[-3:]}" if password else None
            log.debug(f"redis_url: {redis_url}")
            log.debug(f"redis_username: {username}")
            log.debug(f"redis_password: {masked_password}")
            log.debug(f"redis_ssl_ca_certs: {ssl_ca_certs}")
            self.client = redis.Redis.from_url(
                url=redis_url,
                username=username,
                password=password,
                decode_responses=True,
                ssl_ca_certs=ssl_ca_certs,
                socket_timeout=5,
            )

            if self.client.ping():
                log.info("Connected to Redis")
            else:
                log.error("Failed to connect to Redis")

        except ConnectionError as e:
            log.error(f"Failed to connect to Redis: {e}")
        except TimeoutError as e:
            log.error(f"Timed out connecting to Redis: {e}")
        except redis.AuthenticationError as e:
            log.error(f"Authentication failed connecting to Redis: {e}")
        except Exception as e:
            log.error(f"Failed to connect to Redis: {e}")

    def extract_username_from_token(token):
        parts = token.split('.')
        base64_str = parts[1]

        if len(base64_str) % 4 == 2:
            base64_str += "=="
        elif len(base64_str) % 4 == 3:
            base64_str += "="

        json_bytes = base64.b64decode(base64_str)
        json_str = json_bytes.decode('utf-8')
        jwt = json.loads(json_str)

        return jwt['oid']

    @classmethod
    def get_client(cls, redis_url=None, ssl_ca_certs=None, username=None, password=None):
        if cls._instance is None:
            cls(redis_url, ssl_ca_certs, username, password)
        return cls._instance.client

class RedisLock:
    def __init__(self, redis_url, lock_name, timeout_secs, **redis_kwargs):
        self.lock_name = lock_name
        self.lock_id = str(uuid.uuid4())
        self.timeout_secs = timeout_secs
        self.lock_obtained = False
        self.redis = RedisService.get_client(redis_url, **redis_kwargs)

    def aquire_lock(self):
        # nx=True will only set this key if it _hasn't_ already been set
        self.lock_obtained = self.redis.set(
            self.lock_name, self.lock_id, nx=True, ex=self.timeout_secs
        )
        return self.lock_obtained

    def renew_lock(self):
        # xx=True will only set this key if it _has_ already been set
        return self.redis.set(
            self.lock_name, self.lock_id, xx=True, ex=self.timeout_secs
        )

    def release_lock(self):
        lock_value = self.redis.get(self.lock_name)
        if lock_value and lock_value == self.lock_id:
            self.redis.delete(self.lock_name)


class RedisDict:
    def __init__(self, name, redis_url, **redis_kwargs):
        self.name = name
        self.redis = RedisService.get_client(redis_url, **redis_kwargs)

    def __setitem__(self, key, value):
        serialized_value = json.dumps(value)
        self.redis.hset(self.name, key, serialized_value)

    def __getitem__(self, key):
        value = self.redis.hget(self.name, key)
        if value is None:
            raise KeyError(key)
        return json.loads(value)

    def __delitem__(self, key):
        result = self.redis.hdel(self.name, key)
        if result == 0:
            raise KeyError(key)

    def __contains__(self, key):
        return self.redis.hexists(self.name, key)

    def __len__(self):
        return self.redis.hlen(self.name)

    def keys(self):
        return self.redis.hkeys(self.name)

    def values(self):
        return [json.loads(v) for v in self.redis.hvals(self.name)]

    def items(self):
        return [(k, json.loads(v)) for k, v in self.redis.hgetall(self.name).items()]

    def get(self, key, default=None):
        try:
            return self[key]
        except KeyError:
            return default

    def clear(self):
        self.redis.delete(self.name)

    def update(self, other=None, **kwargs):
        if other is not None:
            for k, v in other.items() if hasattr(other, "items") else other:
                self[k] = v
        for k, v in kwargs.items():
            self[k] = v

    def setdefault(self, key, default=None):
        if key not in self:
            self[key] = default
        return self[key]

import json
import redis
import uuid
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.propagate = True

class RedisService:
    def __init__(self, redis_url, ssl_ca_certs, password):
        self.enabled = False
        try:
            self.client = redis.Redis.from_url(url=redis_url,
                                      password=password,
                                      decode_responses=True,
                                      ssl_ca_certs=ssl_ca_certs,
                                      socket_timeout=5,
                                      )

            if self.client.ping():
                logger.info("Connected to Redis")
                self.enabled = True
            else:
                logger.error("Failed to connect to Redis")

        except ConnectionError as e:
            logger.error(f"Failed to connect to Redis: {e}")
        except TimeoutError as e:
            logger.error(f"Timed out connecting to Redis: {e}")
        except redis.AuthenticationError as e:
            logger.error(f"Authentication failed connecting to Redis: {e}")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")

class RedisLock:
    def __init__(self, redis_url, lock_name, timeout_secs, **redis_kwargs):
        self.lock_name = lock_name
        self.lock_id = str(uuid.uuid4())
        self.timeout_secs = timeout_secs
        self.lock_obtained = False
        self.redis = redis.Redis.from_url(redis_url, decode_responses=True, **redis_kwargs)

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
        self.redis = redis.Redis.from_url(redis_url, decode_responses=True,  **redis_kwargs)

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

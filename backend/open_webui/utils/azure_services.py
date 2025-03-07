from datetime import datetime, timedelta, timezone
import base64
import json
import logging

from open_webui.env import SRC_LOG_LEVELS

log = logging.getLogger(__name__)
log.setLevel(SRC_LOG_LEVELS["CONFIG"])

class AzureCredentialService:
    def __init__(self):
        from azure.identity import DefaultAzureCredential
        self.credential = DefaultAzureCredential()
        self.azure_token = { "access_token": None, "expiry_time": None }
        self.resource = "https://redis.azure.com/.default"
        self.get_token()

    # get a token from credential provider, if new token received update azure token cache
    def get_token(self):
        token = self.credential.get_token(self.resource)
        if not token:
            log.error(f"Failed to retrieve Microsoft Entra token for resource: {self.resource}")
            return None
        if token.token != self.azure_token["access_token"]:
            self.azure_token.update({
                'access_token': token.token,
                'expiry_time': token.expires_on
            })
            expires_on = datetime.fromtimestamp(self.azure_token["expiry_time"]).strftime('%Y-%m-%d %H:%M:%S')
            log.info(f"Receive Microsoft Entra token for resource: {self.resource}, expires on: {expires_on}")
        return self.azure_token["access_token"]

    def get_time_to_expire(self):
        if not self.azure_token["expiry_time"]:
            return 0
        time_to_expire = self.azure_token["expiry_time"] - datetime.now(timezone.utc).timestamp() - 300 # 5 mins grace
        return max(time_to_expire, 0)

    def is_expired(self):
        if not self.azure_token["expiry_time"]:
            return True
        expiry_time = datetime.fromtimestamp(self.azure_token["expiry_time"], tz=timezone.utc)
        return datetime.now(timezone.utc) >= (expiry_time - timedelta(minutes=5))

    # extract username from token
    @staticmethod
    def get_username(token):
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

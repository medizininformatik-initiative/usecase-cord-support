import json
import os.path
from typing import List, Optional, Dict, Any

import requests


def get_absolute_file_path(file_name: str):
    return os.path.join(os.path.dirname(__file__), file_name)


def load_train_config() -> Dict[str, Any]:
    """
    :return: Train configuration stored in the ``config.json`` file
    """
    with open(get_absolute_file_path("config.json"), mode="r", encoding="utf-8") as f:
        data = json.load(f)

    if data is None:
        raise IOError("Couldn't read configuration file")

    return data


def load_pseudonyms_from(file_url: str) -> List[str]:
    """
    :return: List of pseudonyms in the file located at the specified URL
    """
    if file_url is None:
        raise ValueError("pseudonym list URL environment variable is not set")

    r = requests.get(file_url)
    r.raise_for_status()

    return r.text.strip().split("\n")


__ENV_RESOLVER_PROXY_URL = "PPRL_RESOLVER_PROXY_URL"
__ENV_SESSION_SECRET = "PPRL_SESSION_SECRET"
__ENV_DATA_DOMAIN = "PPRL_DATA_DOMAIN"
__ENV_PHASE = "PPRL_PHASE"
__ENV_PSEUDONYM_LIST_URL = "PPRL_PSEUDONYM_LIST_URL"


def get_resolver_uri() -> Optional[str]:
    return os.getenv(__ENV_RESOLVER_PROXY_URL)


def get_session_secret() -> Optional[str]:
    return os.getenv(__ENV_SESSION_SECRET)


def get_data_domain() -> Optional[str]:
    return os.getenv(__ENV_DATA_DOMAIN)


def get_phase() -> Optional[str]:
    return os.getenv(__ENV_PHASE)


def get_pseudonym_list_url() -> Optional[str]:
    return os.getenv(__ENV_PSEUDONYM_LIST_URL)


def is_dry_run() -> bool:
    return os.getenv("PPRL_DRY_RUN") is not None


if __name__ == "__main__":
    def print_env(var_name: str, value: str):
        print(f"  {var_name}: {value if value is not None else '[not set]'}")


    print(f"Environment variables:")

    print_env(__ENV_RESOLVER_PROXY_URL, get_resolver_uri())
    print_env(__ENV_PSEUDONYM_LIST_URL, get_pseudonym_list_url())
    print_env(__ENV_SESSION_SECRET, get_session_secret())
    print_env(__ENV_DATA_DOMAIN, get_data_domain())
    print_env(__ENV_PHASE, get_phase())

    print(f"Train configuration: {load_train_config()}")

    pseudonym_count: Optional[int] = None

    # noinspection PyBroadException
    try:
        pseudonym_count = len(load_pseudonyms_from(get_pseudonym_list_url()))
    except Exception:
        pass

    print(f"Pseudonym count: {'[unavailable]' if pseudonym_count is None else pseudonym_count}")

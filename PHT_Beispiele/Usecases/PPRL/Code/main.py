import csv
import json
import logging
import math
import os.path
import random
import time
from datetime import datetime

import requests
from requests import Response, JSONDecodeError

from config import load_train_config, load_pseudonyms_from, get_resolver_uri, get_session_secret, get_data_domain, \
    get_phase, is_dry_run, get_pseudonym_list_url

logging.basicConfig(format="%(levelname)s %(asctime)s %(message)s", level=logging.DEBUG)

PPRL_PHASE_SUBMIT = "submit"
PPRL_PHASE_RESULT = "result"
PPRL_PHASES = (PPRL_PHASE_RESULT, PPRL_PHASE_SUBMIT)


def main():
    def check_response(r: Response, status_code=200):
        """
        Checks a response for a status code. Throws an error and tries to read information from the response in case
        of failure.

        :param r: response object to check
        :param status_code: expected status code
        :return: response object
        """
        if r.status_code != status_code:
            try:
                message = r.json()

                if "detail" in message:
                    message = message["detail"]
            except JSONDecodeError:
                message = "response is not JSON"

            raise ConnectionError(f"failed to perform request (expected {status_code}, got {r.status_code}): {message}")

        return r

    logging.info("Loading configuration...")

    train_config = load_train_config()
    logging.info(json.dumps(train_config, indent=2))

    logging.info("Validating environment variables...")

    pseudonym_url = get_pseudonym_list_url()
    resolver_uri = get_resolver_uri()
    session_secret = get_session_secret()
    data_domain = get_data_domain()
    phase = get_phase().lower()

    if None in (resolver_uri, session_secret, data_domain, phase, pseudonym_url):
        logging.error("Some of the required environment variables aren't set")
        logging.error("Please verify the variables you've set in the station UI")
        exit(1)

    if phase not in PPRL_PHASES:
        logging.error("Unrecognized phase, must be one of %s", PPRL_PHASES)
        exit(1)

    auth_header = {"Authorization": f"Bearer {session_secret}"}

    logging.info("  Resolver Proxy URL: %s", resolver_uri)
    logging.info("  Session secret: %s...", session_secret[:4])
    logging.info("  Data domain: %s", data_domain)
    logging.info("  Phase: %s", phase)
    logging.info("  Pseudonym list URL: %s", pseudonym_url)

    if phase == PPRL_PHASE_SUBMIT:
        logging.info("Starting pseudonym submission")
        logging.info("Loading pseudonyms...")

        pseudonyms = load_pseudonyms_from(pseudonym_url)

        logging.info("  Pseudonym count: %d", len(pseudonyms))
        logging.info("Submitting pseudonyms...")

        if not is_dry_run():
            logging.info("Registering session at resolver...")
            t = -time.time()
            check_response(requests.post(resolver_uri, json=train_config, headers=auth_header), status_code=201)
            t += time.time()
            logging.info("Registration took %d ms", int((t * 1000) / 1))

            logging.info("Submitting pseudonyms to resolver...")
            t = -time.time()
            check_response(requests.put(resolver_uri, json=pseudonyms, headers=auth_header), status_code=202)
            t += time.time()
            logging.info("Submission took %d ms", int((t * 1000) / 1))

            # this is necessary to avoid a common error in the train station ui
            logging.info("Writing junk...")

            junk_filename = "junk_" + str(math.floor(time.time())) + ".txt"

            with open(junk_filename, mode="w", encoding="utf-8") as f:
                f.write(str(random.randint(0, 100)) + "\n")

        logging.info("Pseudonyms were successfully submitted :)")
    elif phase == PPRL_PHASE_RESULT:
        logging.info("Fetching results from broker...")

        matches = []

        if not is_dry_run():
            t = -time.time()
            matches = check_response(requests.get(resolver_uri, headers=auth_header)).json()["matches"]
            t += time.time()
            logging.info("Fetching results took %d ms", int((t * 1000) / 1))

        logging.info("Found %d matches at this station", len(matches))

        now = datetime.now().strftime("%Y%m%d%H%M%S")
        output_path = os.path.join(os.path.dirname(__name__), f"results_{now}.csv")

        logging.info("Writing results to output file at %s...", output_path)

        if not is_dry_run():
            with open(output_path, mode="w", newline="", encoding="utf-8") as f:
                fieldnames = ["psn", "sim", "own_meta", "ref_meta"]
                writer = csv.DictWriter(f, fieldnames=fieldnames)

                writer.writeheader()
                print(",".join(fieldnames))

                for match in matches:
                    psn = match["vector"]["id"]
                    sim = str(match["similarity"])
                    own_meta = json.dumps(match["vector"]["metadata"])
                    ref_meta = json.dumps(match["referenceMetadata"])

                    writer.writerow({
                        "psn": psn,
                        "sim": sim,
                        "own_meta": own_meta,
                        "ref_meta": ref_meta
                    })
                    print(",".join([psn, sim, own_meta, ref_meta]))

        logging.info("All done :)")
    else:
        logging.error("Unimplemented phase '%s'", phase)
        exit(1)


if __name__ == "__main__":
    # noinspection PyBroadException
    try:
        main()
    except Exception:
        logging.error("Failed to execute train", exc_info=True)

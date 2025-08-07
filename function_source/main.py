# function_source/main.py

import functions_framework
from . import utils
import csv
import json
import time

@functions_framework.cloud_event
def read_and_publish(cloud_event):
    """
    Triggered by a change to a Cloud Storage bucket.
    Reads a file line by line and publishes each line to a Pub/Sub topic.
    """
    data = cloud_event.data
    bucket_name = data["bucket"]
    file_name = data["name"]

    print(f"Processing file: {file_name} from bucket: {bucket_name}.")

    # Get the bucket and blob (file)
    bucket = utils.storage_client.get_bucket(bucket_name)
    blob = bucket.blob(file_name)

    # Download the file's content as a string and split into lines
    lines = blob.download_as_text().splitlines()

    print(f"Found {len(lines)} lines to publish to topic '{utils.PUBSUB_TOPIC}'.")


    csv_reader = csv.DictReader(lines)
    for index, row in enumerate(csv_reader):
        message_data = json.dumps(row).encode("utf-8")
        future = utils.publisher.publish(utils.get_topic_path(utils.publisher), data=message_data)
        print(f"Published message ID: {future.result()} for row {index+1}")
        time.sleep(0.3)  # Sleep to simulate streaming

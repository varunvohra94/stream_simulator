# function_source/utils.py
import os
import csv
import json

from google.cloud import pubsub_v1, storage

# Get environment variables
PROJECT_ID = os.environ.get("PROJECT_ID")
PUBSUB_TOPIC = os.environ.get("PUBSUB_TOPIC")

# Construct the full topic path
def get_storage_client():
    """
    Returns the Google Cloud Storage client.
    """
    return storage.Client()

def get_publisher_client():
    """
    Returns the Google Cloud Pub/Sub publisher client.
    """
    return pubsub_v1.PublisherClient()

# Initialize the clients
storage_client = get_storage_client()
publisher = get_publisher_client()


def get_topic_path(publisher):
    """
    Returns the full topic path for the Pub/Sub topic.
    """
    return publisher.topic_path(PROJECT_ID, PUBSUB_TOPIC)


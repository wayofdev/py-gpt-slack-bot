# -*- coding: utf-8 -*-
import os
import openai
import logging
from slack_bolt import App
import re

logging.basicConfig(level=logging.DEBUG)

app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET"),
)

api_key = os.environ.get("OPENAI_API_KEY")
openai.api_key = api_key


def send_message(message_log):
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=message_log,
        max_tokens=3800,
        stop=None,
        temperature=0.7,
    )
    # Find the first response from the chatbot that has text in it
    # (some responses may not have text)
    for choice in response.choices:
        if "text" in choice:
            return choice.text

    # If no response with text is found, return the first response's content
    # (which may be empty)
    return response.choices[0].message.content


def strip_mentions(text):
    return re.sub('(?:\s)<@[^, ]*|(?:^)<@[^, ]*', '', text)


@app.event("app_mention")
def handle_mention(event, say):
    # Strip mentions from the message text
    prompt = strip_mentions(event['text'])
    response = send_message([{"role": "user", "content": prompt}])
    say(text=response)


@app.event("message.im")
def handle_direct_message(event, say):
    prompt = strip_mentions(event['text'])
    response = send_message([{"role": "user", "content": prompt}])
    say(text=response)


@app.event("message.groups")
def handle_group_message(event, say):
    prompt = strip_mentions(event['text'])
    response = send_message([{"role": "user", "content": prompt}])
    say(text=response)


@app.event("event_callback")
def handle_event_callback(event, say):
    if event["type"] == "url_verification":
        # Handle Slack Events API challenge requests
        say(text=event["challenge"])


if __name__ == "__main__":
    app.start(port=int(6000))

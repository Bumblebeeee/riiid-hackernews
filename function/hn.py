import requests
import time
import sys
import logging
from datetime import datetime, timedelta

HNAPI_MAXITEM = "https://hacker-news.firebaseio.com/v0/maxitem.json"
HNAPI_ITEM = "https://hacker-news.firebaseio.com/v0/item/{}.json"

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler())


def lambda_handler(event, context):
    h = event["h"]
    logger.info("Retrive threads within past {} Hours".format(h))
    return get_hn(h)


def get_hn(h):
    items, roots = [], []
    past = get_unix_time(h)
    maxitem = requests.get(HNAPI_MAXITEM).json()
    for id in range(maxitem, 0, -1):
        rbody = requests.get(HNAPI_ITEM.format(id)).json()
        logger.debug("{},{},{},{},{}".format(
            rbody["id"], rbody["type"], rbody["time"], past, rbody["time"] > past))
        if rbody["time"] > past:
            items.append(rbody)
        else:
            break
    roots = list(map(get_parent, items))
    roots = sorted(set(roots), key=roots.index)
    logger.debug(roots)
    comments = []
    get_children(roots, 0, comments)
    deepest_comment = max(comments)
    thread = []
    get_thread(deepest_comment[1], thread)
    logger.debug(deepest_comment)
    logger.debug(thread)
    return thread


def get_thread(item_id, thread):
    rbody = requests.get(HNAPI_ITEM.format(item_id)).json()
    thread.append(rbody)
    if "parent" in rbody.keys():
        thread = get_thread(rbody["parent"], thread)
    return thread


def get_children(nodes, depth, comments):
    for node in nodes:
        rbody = requests.get(HNAPI_ITEM.format(node)).json()
        if "kids" in rbody.keys():
            get_children(rbody["kids"], depth + 1, comments)
        comments.append([depth, rbody["id"]])


def get_parent(item):
    if "parent" in item.keys():
        rbody = requests.get(HNAPI_ITEM.format(item["parent"])).json()
        return get_parent(rbody)
    else:
        return item["id"]


def get_unix_time(h):
    past = datetime.now() - timedelta(hours=h)
    unixtime = time.mktime(past.timetuple())
    return unixtime


if __name__ == '__main__':
    h = float(sys.argv[1])
    logger.debug("Past {} Hours".format(h))
    print(get_hn(h))

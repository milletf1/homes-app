"""Provides methods for querying the homes.co.nz API."""
import requests
from .urls import *

def search_address(address):
  """Returns a list of properties that have a Title that has text that matches
     the address arg.

      Args:
          address: The value that is used to determine the properties that will
            be returned.

      Returns:
        A list of dicts that contain details about properties, including a
        Title that can be used as a parameter for retrieving a property
        id.
  """
  url = BASE_URL + SEARCH_ADDRESS_ENDPOINT + address
  response = requests.get(url)
  json = response.json()
  if  "Results" in json:
    return json["Results"]
  else:
    return []

def get_property_id(address):
  """Returns a property id that can be used to get information about a
     property.

      Args:
        address: Address of the property to get an id for. Should be formatted
          like the Title value of property dicts returned by search_address.
          Ideally, you should just use the Title value.

      Returns:
        A property id which can then be used to get property information.
  """
  url = BASE_URL + GET_PROPERTY_ID_ENDPOINT + address
  response = requests.get(url)
  return response.json()["property_id"]

def get_property_overview(property_id):
  """Returns basic property data.

      Args:
        property_id: Id of the property to get data for.

      Returns:
        An overview of a property.
  """
  url = BASE_URL + GET_PROPERTY_ENDPOINT + property_id
  response = requests.get(url)
  cards = response.json()["cards"]
  if len(cards) < 1:
    return None
  else:
    return cards[0]

def get_property_details(property_id):
  """Returns more in depth property details.

      Args:
        property_id: Id of the property to get data for.

      Returns:
        Details about the property.
  """
  details_endpoint = GET_DETAILS_ENDPOINT.replace("0", property_id)
  url = BASE_URL + details_endpoint
  response = requests.get(url)
  json = response.json()
  if "property" in json:
    return json["property"]
  else:
    return None

def get_property_timeline(property_id):
  """Returns a timeline of property events (RV, Sale etc...).

      Args:
        property_id: Id of the property to get data for.

      Returns:
        A list of property event dicts.
  """
  timeline_endpoint = GET_TIMELINE_ENDPOINT.replace("0", property_id)
  url = BASE_URL + timeline_endpoint
  response = requests.get(url)
  json = response.json()
  if "events" in json:
    return json["events"]
  else:
    return None

def get_estimate_history(property_id):
  """Returns an estimate history for a property.

      Args:
        property_id: Id of the property to get data for.

      Returns:
        A dict with the following keys:
          * property_estimate_history - a history of the property's estimated
            value
          * city_estimate_history - a history of the city's property values
          * suburb_estimate_history - a history of the suburb's property values
          * forecast - a forecast of the property's future value
        NOTE: I'm not sure if I have described dict values correctly ¯\_(ツ)_/¯
  """
  url = BASE_URL + GET_ESTIMATE_HISTORY_ENDPOINT + property_id
  response = requests.get(url)
  return response.json()
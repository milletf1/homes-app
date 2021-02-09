"""Proxy server for homes.co.nz API."""
from flask import Flask, request
from flask_cors import CORS
import proxy

app = Flask(__name__)
CORS(app)

@app.route("/search")
def search_address():
  address = request.args.get('address')
  if address == None:
    return { "error": "Missing address parameter" }, 400
  else:
    results = proxy.search_address(address)
    return { "results": results }

@app.route("/property-id")
def get_property_id():
  address = request.args.get('address')
  if address == None:
    return { "error": "Missing address parameter" }, 400
  else:
    id = proxy.get_property_id(address)
    if len(id) == 0:
        return { "error": "Property id not found" }, 404
    else:
      return { "address": address, "id": id }

@app.route("/overview/")
@app.route("/overview/<id>")
def get_overview(id=None):
  if id == None:
    return { "error": "Missing id parameter" }, 400
  else:
    overview = proxy.get_property_overview(id)
    if overview == None:
      return { "error": "Property not found" }, 404
    else:
      return overview

@app.route("/timeline/")
@app.route("/timeline/<id>")
def get_timeline(id=None):
  if id == None:
    return { "error": "Missing id parameter" }, 400
  else:
    timeline = proxy.get_property_timeline(id)
    if timeline == None:
      return { "error": "Property not found" }, 404
    else:
      return { "timeline": timeline }

@app.route("/estimate-history/")
@app.route("/estimate-history/<id>")
def get_estimate_history(id=None):
  if id == None:
    return { "error": "Missing id parameter" }, 400
  else:
    estimate_history = proxy.get_estimate_history(id)
    if "error" in estimate_history:
      return { "error": "Property not found" }, 404
    else:
      return estimate_history

@app.route("/details")
@app.route("/details/<id>")
def get_details(id=None):
  if id == None:
    return { "error", "Missing id parameter" }, 400
  else:
    details = proxy.get_property_details(id)
    if "error" in details:
      return { "error": "Property not found" }, 404
    else:
      return details

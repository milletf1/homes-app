import * as axios from "axios"
import { deltaToPercentage, getClosestObjectByDate, latestDateReduce } from "./util"

const PROPERTY_SALE_KEY = "property_sale"
const PROPERTY_VALUATION_KEY = "valuation"

const CACHE_TIME = 8 * 60 * 60 * 1000

export async function getPropertyData(addressDetails) {

    const cached = detailsCache.getPropertyData(addressDetails.id)

    if (!!cached) {
        const timeNow = new Date().getTime()
        const timeCached = cached.time

        if (timeNow - timeCached <= CACHE_TIME)  return cached.data
    }

    const results = await Promise.all([
        getTimeline(addressDetails.id),
        getEstimateHistory(addressDetails.id),
        getDetails(addressDetails.id),
    ]);
    const [timeline, history, details] = results
    const data = {
        ...extractData(timeline, history, details),
        address: addressDetails.address,
    }
    detailsCache.addPropertyData(addressDetails.id, data)

    return data
}

export async function getOverview(id) {
    try {
        const result = await axios.get(`${URL}/overview/${id}`)
        return result.data
    } catch(err) {
        console.error(err)
        return null
    }
}

export async function getTimeline(id) {
    try {
        const result = await axios.get(`${URL}/timeline/${id}`)
        return result.data
    } catch(err) {
        console.error(err)
        return null
    }
}

export async function getEstimateHistory(id) {
    try {
        const result = await axios.get(`${URL}/estimate-history/${id}`)
        return result.data
    } catch(err) {
        console.error(err)
        return null
    }
}

export async function getDetails(id) {
    try {
        const result = await axios.get(`${URL}/details/${id}`)
        return result.data
    } catch (err) {
        console.error(err)
        return null
    }
}

function extractData(timeline, history, details) {
    const historyData = extractHistoryData(history)
    const timelineData = extractTimelineData(timeline)
    const detailsData = extractDetailsData(details)
    const calculatedData = extractCalculatedData(historyData, timelineData, history)

    return {
        ...historyData,
        ...timelineData,
        ...detailsData,
        ...calculatedData,
    }
}

function extractHistoryData(historyResponse) {
    const data = {
        estimate: null,
        estimateDate: null,
    }

    if (historyResponse == null || historyResponse.property_estimate_history == null) return data

    const { property_estimate_history: history } = historyResponse
    const dateReduceFn = latestDateReduce("date")
    const latestEstimate = history.reduce(dateReduceFn, null)

    if (latestEstimate !== null) {
        data.estimate = Math.round(latestEstimate.estimate)
        data.estimateDate = new Date(latestEstimate.date).getTime()
    }
    return data
}

function extractTimelineData(timelineRespose) {
    const data = {
        rateableValue: null,
        rateableValueDate: null,
        salePrice: null,
        saleDate: null,
        rvSaleDiff: null,
    }

    if (timelineRespose == null || timelineRespose.timeline == null) return data

    const { timeline } = timelineRespose
    const dateReduceFn = latestDateReduce("date")
    const sales = timeline.filter(item => item.key === PROPERTY_SALE_KEY)
    const valuations = timeline.filter(item => item.key === PROPERTY_VALUATION_KEY)
    const latestSale = sales.reduce(dateReduceFn, null)
    const latestValuation = valuations.reduce(dateReduceFn, valuations)

    if (latestValuation !== null) {
        data.rateableValue = latestValuation.data.capital_value
        data.rateableValueDate = new Date(latestValuation.date).getTime()
    }

    if (latestSale !== null) {
        const saleDate = new Date(latestSale.date)
        data.salePrice = latestSale.data.price
        data.saleDate = saleDate.getTime()

        if (valuations.length > 0) {
            const closestRvData = getClosestObjectByDate("date")(saleDate, valuations)

            if (closestRvData != null) {
                data.rvSaleDiff = deltaToPercentage(data.salePrice, closestRvData.data.capital_value)
            }
        }
    }
    return data
}

function extractDetailsData(detailsResponse) {
    const data = {
        baths: null,
        bedrooms: null,
        carParks: null,
        floorArea: null,
        landArea: null
    }

    if (detailsResponse == null) return data

    if (detailsResponse.bath_estimate) data.baths = detailsResponse.bath_estimate
    if (detailsResponse.bed_estimate) data.bedrooms = detailsResponse.bed_estimate
    if (detailsResponse.num_car_spaces) data.carParks = detailsResponse.num_car_spaces
    if (detailsResponse.floor_area) data.floorArea = detailsResponse.floor_area
    if (detailsResponse.land_area) data.landArea = detailsResponse.land_area

    return data
}

function extractCalculatedData(historyData, timelineData, historyResponse) {
    const data = {
        estimateRvDiff: null,
        estimateSaleDiff: null,
    }

    if (historyData == null
        || historyData.estimate == null
        || timelineData == null
        || historyResponse == null) {
        return data
    }
    const { property_estimate_history: history } = historyResponse

    if (timelineData.rateableValue != null) {
        data.estimateRvDiff = deltaToPercentage(historyData.estimate, timelineData.rateableValue)
    }

    if (timelineData.salePrice != null && timelineData.saleDate != null) {
        const saleDate = new Date(timelineData.saleDate)
        const closestHistory = getClosestObjectByDate("date")(saleDate, history)

        if (closestHistory != null) {
            data.estimateSaleDiff = deltaToPercentage(timelineData.salePrice, closestHistory.estimate)
        }
    }
    return data
}

const detailsCache = (function() {
    const CACHE_KEY = "homes-app:cache"

    function getCache() {
        const cache = localStorage.getItem(CACHE_KEY)
        if (!cache) {
            setCache({})
            return{}
        }
        return JSON.parse(cache)
    }

    function setCache(cache) {
        localStorage.setItem(CACHE_KEY, JSON.stringify(cache))
    }

    function addPropertyData(addressId, data) {
        const cache = getCache()
        const time = new Date().getTime()
        const payload = {
            time,
            data
        }
        cache[addressId] = payload
        setCache(cache)
    }

    function deletePropertyData(addressId) {
        const cache = getCache()
        delete cache(addressId)
        setCache(cache)
    }

    function getPropertyData(addressId) {
        const cache = getCache()
        return cache[addressId]
    }

    return {
        addPropertyData,
        getPropertyData,
        deletePropertyData
    }
})()
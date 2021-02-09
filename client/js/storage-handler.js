export const StorageHandler = (function() {
    const WATCHLIST_KEY = "homes-app:watchlist"

    function getWatchlist() {
        const watchlist = localStorage.getItem(WATCHLIST_KEY)
        if (!watchlist) {
            setWatchlist({})
            return {}
        }
        return JSON.parse(watchlist)
    }

    function setWatchlist(watchlists) {
        localStorage.setItem(WATCHLIST_KEY, JSON.stringify(watchlists))
    }

    function addWatchlistItem(watchlistItem) {
        const watchlist = getWatchlist()
        watchlist[watchlistItem.id] = watchlistItem
        setWatchlist(watchlist)
    }

    function deleteWatchlistItem(watchlistItem) {
        const watchlist = getWatchlist()
        delete watchlist[watchlistItem.id]
        setWatchlist(watchlist)
    }

    function getWatchlistArray() {
        const watchlist = getWatchlist()
        const watchlistArr = []
        Object.keys(watchlist).forEach(function(id) {
            watchlistArr.push(watchlist[id])
        })
        return watchlistArr
    }

    return {
        getWatchlist: getWatchlistArray,
        addWatchlistItem: addWatchlistItem,
        deleteWatchlistItem: deleteWatchlistItem
    }
})()
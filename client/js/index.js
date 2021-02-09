import { StorageHandler } from "./storage-handler"
import { getPropertyData } from "./api"

const app = Elm.Main.init({
    node: document.getElementById("main"),
    flags: {
        watchlist: StorageHandler.getWatchlist(),
        url: URL,
    }
})

app.ports.postWatchlistItems.subscribe((watchlistItems) => {
    watchlistItems.forEach((watchlistItem) => {
        StorageHandler.addWatchlistItem(watchlistItem)
    })
    broadcastWatchlistUpdate()
})

app.ports.deleteWatchlistItems.subscribe((watchlistItems) => {
    watchlistItems.forEach((watchlistItem) => {
        StorageHandler.deleteWatchlistItem(watchlistItem)
    })
    broadcastWatchlistUpdate()
})

app.ports.getPropertyData.subscribe(async (watchList) => {
    const results = await Promise.all(watchList.map(async (item) => await getPropertyData(item)))
    app.ports.updatePropertyData.send(results)
})

function broadcastWatchlistUpdate() {
    const watchlist = StorageHandler.getWatchlist()
    app.ports.updateWatchlist.send(watchlist)
}

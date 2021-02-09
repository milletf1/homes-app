
/**
 * Returns a function that compares two object that have a date string
 * returns the object with the latest date
 * @param {string} property The object property that contains the date string to compare
 */
export function latestDateReduce(property) {
    return (prev, cur) => {
        if (prev == null || prev[property] == null) return cur
        if (cur == null || cur[property] == null) return prev
        return new Date(prev[property]).getTime() > new Date(cur[property]).getTime()
            ? prev : cur
    }
}

/**
 * Returns a function that takes a date {date} and an array of objects which has a date property
 * {items} as parameters. The function searches the array for an object that has a date which is
 * closest to the given date and returns it.
 * @param {string} The object property that contains the date string to compare
 */
export function getClosestObjectByDate(property) {
    return (date, items) => {
        if (date == null || items == null) return null

        const dateTime = date.getTime()
        let closestItem;
        let closestItemTimeDelta;

        for (let item of items) {
            if (item[property] == null) continue

            const itemTime = new Date(item[property]).getTime()
            const itemTimeDelta = Math.abs(dateTime - itemTime)

            if (closestItem == null
                || closestItemTimeDelta == null
                || itemTimeDelta < closestItemTimeDelta) {
                closestItem = item
                closestItemTimeDelta = itemTimeDelta
            }
        }
        return closestItem
    }
}

/**
 * Returns the percentage difference between two numbers as a decimal
 */
export function deltaToPercentage(a, b) {
    return (a - b) / b
}
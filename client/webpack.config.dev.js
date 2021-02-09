const HtmlWebpackPlugin = require("html-webpack-plugin")
const MiniCssExtractPlugin = require("mini-css-extract-plugin")
const CopyPlugin = require("copy-webpack-plugin")
const config = require("./config.json")
const path = require("path")
const webpack = require("webpack")

module.exports = {
    entry: "./js/index.js",
    output: {
        filename: "main-js.js",
        path: path.resolve(__dirname, "dev-build")
    },
    mode: "development",
    module: {
        rules: [
            {
                test: /\.s(a|c)ss$/i,
                use: [
                    MiniCssExtractPlugin.loader,
                    "css-loader",
                    "sass-loader"
                ]
            }
        ]
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: "./html/index.ejs",
            baseHref: "/dev-build/"
        }),
        new MiniCssExtractPlugin(),
        new CopyPlugin({
            patterns: [
                { from: "assets", to: "assets" }
            ]
        }),
        new webpack.DefinePlugin({
            URL: JSON.stringify(config.devApiUrl),
        }),
    ],
    resolve: {
        alias: {
            axios: path.resolve(__dirname, "node_modules/axios/dist/axios.js")
        }
    }
}
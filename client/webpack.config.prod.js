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
        path: path.resolve(__dirname, "dist")
    },
    mode: "production",
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
        new HtmlWebpackPlugin({ template: "./html/index.ejs" }),
        new MiniCssExtractPlugin(),
        new CopyPlugin({
            patterns: [
                { from: "assets", to: "assets" }
            ]
        }),
        new webpack.DefinePlugin({
            URL: JSON.stringify(config.prodApiUrl),
        }),
    ],
    resolve: {
        alias: {
            axios: path.resolve(__dirname, "node_modules/axios/dist/axios.js")
        }
    }
}
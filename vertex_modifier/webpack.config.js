'use strict'

var webpack = require('webpack');
var path = require('path');

module.exports = {
    output: {
        path: __dirname + '/build',
        filename: 'app.js',
    },
    context: __dirname,
    entry: [
        __dirname + '/main.coffee',
    ],
    stats: {
        colors: true,
        reasons: true
    },
    module: {
        rules: [
            {
                test: /\.coffee$/,
                loaders: [
                    'coffee-loader',
                    // 'source-map-loader',
                ]
            },
            {
                test: /\.(png|jpe?g|gif)$/i,
                loader: 'url-loader?limit=18000&name=[path][name].[ext]',
            },
            {test: /\.svg$/, loader: 'url-loader?mimetype=image/svg+xml'},
            {test: /\.woff2?$/, loader: 'url-loader?mimetype=application/font-woff'},
            {test: /\.eot$/, loader: 'url-loader?mimetype=application/font-woff'},
            {test: /\.ttf$/, loader: 'url-loader?mimetype=application/font-woff'},
            {test: /\.json$/, loader: 'json-loader'},
            {test: /\.html$/, loader: 'raw-loader'},
        ]
    },
    // devtool: 'inline-source-map',
    plugins: [
        /*
        new webpack.BannerPlugin([
            'Application (c) 20xx Your name or company. All rights reserved.',
        ].join('\n'), {
            raw: false
        }),
        */
        new webpack.DefinePlugin({
            "process.env": {
                NODE_ENV: '"production"'
            },
        }),
        /*
        new webpack.optimize.UglifyJsPlugin({
            screw_ie8: true,
            sourceMap: false,
            compress: { warnings: true },
        }),
        */
    ],
    resolve: {
        extensions: ['.webpack.js', '.web.js', '.js', '.coffee', '.json'],
        alias: {
            // You can use this to override some packages and use local versions
            'myou-engine': path.resolve(__dirname+'/../../myou'),
        },
    },
}

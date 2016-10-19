To run one of the examples locally, run `npm update` in the example folder and then you can choose one of these two alternatives:

1. From the browser using __Webpack__

    ```
    cd [myou-examples]/[example]
    webpack
    node run_server.js
    ```

    Alternatively, you can configure your browser to allow file access to avoid using the server.

2. Natively using __Electron__

    ```
    cd [myou-examples]/[example]
    node electron_launcher.js
    ```

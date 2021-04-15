<?php
header("Server: noyb");
header("X-Powered-By: noyb");

if ($_SERVER["REQUEST_URI"] == "/") {
        file_put_contents("php://stdout", "healthcheck.php: Responding OK to healthcheck request\n");
        header("HTTP/1.0 200 OK");
        echo "<!doctype html>";
        echo "<html><body>everything's fine, go away</body></html>\n";
} else {
        file_put_contents("php://stdout", "healthcheck.php: Unknown request made: {$_SERVER["REQUEST_URI"]}\n");
        header("HTTP/1.0 418 I'm a teapot!");
        echo "<!doctype html>";
        echo "<html><body>I have no idea what you want, go away</body></html>\n";
}

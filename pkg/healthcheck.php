<?php
header("Server: noyb");
header("X-Powered-By: noyb");

if ($_SERVER["REQUEST_URI"] == "/") {
        header("HTTP/1.0 200 OK");
        echo "<!doctype html>";
        echo "<html><body>everything's fine, go away</body></html>\n";
} else {
        header("HTTP/1.0 418 I'm a teapot!");
        echo "<!doctype html>";
        echo "<html><body>I have no idea what you want, go away</body></html>\n";
}

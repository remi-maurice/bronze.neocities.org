let speed = 1;  // Image speed, you will need to tweak xspeed & yspeed too, I made a comment.
let scale = 100; // Image scale
let canvas;
let ctx;
let icons = [];
let currentHue = 0; // Initial hue value

(function main(){
    canvas = document.getElementById("tv-screen");
    ctx = canvas.getContext("2d");

    // Draw the "tv screen"
    canvas.width  = 400;
    canvas.height = 400;
    initIcons(1);
    update();
})();

function update() {
    // Change fill hue here
    ctx.fillStyle = `hsl(${currentHue}, 20%, 60%)`;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    icons.forEach((icon, index) => {
        // Hue changer for icons
        ctx.filter = `hue-rotate(${icon.hue}deg)`;
        ctx.drawImage(icon.img, icon.x, icon.y, icon.width * scale, icon.height * scale);

        // Move the icon
        icon.x += icon.xspeed * speed;
        icon.y += icon.yspeed * speed;

        // Check for collision with boundaries
        checkHitBox(icon);

        // Check for collision with other icons
        for (let i = index + 1; i < icons.length; i++) {
            checkIconCollision(icon, icons[i]);
        }
    });

    // Reset hue rotation
    ctx.filter = 'none';

    // Call update function recursively
    requestAnimationFrame(update);
}

function initIcons(numIcons) {
    const folderPath = '../img/bouncy/'; // Your folder path
    const images = [ // Your images that you want to ~* Disco-bounce *~ 
        '1.png',
        '2.png',
        '3.png',
        '4.png',
        '5.png',
        '6.png',
        '7.png',
        '8.png',
        '9.png',
        '10.png',
        '11.png',
        '12.png',
        '13.png',
        '14.png',
        '15.png',
        '16.png',
        '18.png'
    ];

    shuffleArray(images);

    // Clear existing icons before adding new ones
    icons = [];

    for (let i = 0; i < numIcons; i++) {
        const icon = {
            x: Math.random() * (canvas.width - 300),
            y: Math.random() * (canvas.height - 300),
            xspeed: 1,    // Tweak here too! 
            yspeed: 1,    // Tweak here too!
            img: new Image(),
            width: 1,
            height: 1,
            hue: 0 // Initial hue, 0 is good.
        };
        const randomImage = images[i % images.length];
        icon.img.src = folderPath + '/' + randomImage;
        icon.img.onload = () => {
            icon.width = icon.img.width;  // Set width based on image size
            icon.height = icon.img.height; // Set height based on image size
        };
        icons.push(icon);
    }
}

function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
}

function checkHitBox(icon) {
    let hitBoundary = false;

    if (icon.x + icon.width * scale >= canvas.width || icon.x <= 0) {
        icon.xspeed *= -1 + Math.random() * 0.1;  // Add randomness
        hitBoundary = true;
        icon.hue += 5; // Gradual hue change
    }

    if (icon.y + icon.height * scale >= canvas.height || icon.y <= 0) {
        icon.yspeed *= -1 + Math.random() * 0.1;  // Add randomness
        hitBoundary = true;
        icon.hue += 5; // Gradual hue change
    }

    if (hitBoundary) {
        currentHue += 5; // Gradual change when the first icon hits the boundary
    }
}

function checkIconCollision(icon1, icon2) {
    // Calculate distance between the centers of the two icons
    const dx = icon2.x - icon1.x;
    const dy = icon2.y - icon1.y;
    const distance = Math.sqrt(dx * dx + dy * dy);

    // Check if the icons are colliding
    if (distance < (icon1.width * scale + icon2.width * scale) / 2) {
        // Swap speeds to simulate bouncing off each other
        const tempXSpeed = icon1.xspeed - 0.5;
        const tempYSpeed = icon1.yspeed - 0.25;
        icon1.xspeed = icon2.xspeed + 0.5;
        icon1.yspeed = icon2.yspeed + 0.25;
        icon2.xspeed = tempXSpeed;
        icon2.yspeed = tempYSpeed;
    }
}

// Popup

document.addEventListener("DOMContentLoaded", function () {
    var popup = document.getElementById("popup");
    var popupBackButton = document.getElementById("popupBackButton");
    var popupContinueButton = document.getElementById("popupContinueButton");
    var canvasContainer = document.querySelector(".canvas-container");

    // Show the popup initially
    popup.style.display = "block";

    // Add event listener to the "Go Back" button
    popupBackButton.addEventListener("click", function () {
      // Redirect to index.html
      window.location.href = "index.html";
    });

    // Add event listener to the "Continue" button
    popupContinueButton.addEventListener("click", function () {
      // Hide the popup
      popup.style.display = "none";

      // Display the canvas container
      canvasContainer.style.display = "block";

      // Call any function to start canvas drawing or manipulation
      // Example: startDrawing();
    });

    let initialIconCount = 1;

    // Button to increase icon count
    document.getElementById("increaseIconCountButton").addEventListener("click", function() {
        initialIconCount += 1; // Increase icon count by 1
        initIcons(initialIconCount); // Reinitialize icons with the new count
    });

    // Speed control buttons
    document.getElementById("increaseSpeedButton").addEventListener("click", function() {
        if (speed < 10) speed += 0.3; // Max speed limit
    });

    document.getElementById("decreaseSpeedButton").addEventListener("click", function() {
        if (speed > 0.1) speed -= 0.3; // Min speed limit
    });

    // Scale control
    document.getElementById("increaseScaleButton").addEventListener("click", function() {
        scale += 10;
    });

    document.getElementById("decreaseScaleButton").addEventListener("click", function() {
        scale -= 10;
    });

    // Button to reset icon count and restart script
    document.getElementById("resetIconCountButton").addEventListener("click", function() {
        icons = []; // Clear existing icons
        initIcons(initialIconCount); // Reinitialize icons with the new count
    });
});

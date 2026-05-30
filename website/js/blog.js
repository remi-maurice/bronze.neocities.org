const posts = document.querySelectorAll(".blog-post");
const links = document.querySelectorAll(".blog-nav a");

/* ========================= */
/* ACTIVE STATE MANAGEMENT  */
/* ========================= */

function setActive(id) {
    posts.forEach(p => {
        p.classList.toggle("active", p.id === id);
    });

    links.forEach(l => {
        l.classList.toggle("active", l.dataset.target === id);
    });
}

/* ========================= */
/* SCROLL LOGIC (rect.top)  */
/* ========================= */

function updateActiveFromScroll() {
    const triggerLine = window.innerHeight * 0.5; 
    // ligne de déclenchement (30% du viewport)

    let current = null;
    let bestDistance = Infinity;

    posts.forEach(post => {
        const rect = post.getBoundingClientRect();

        // priorité aux posts déjà passés dans la zone haute
        const distance = Math.abs(rect.top - triggerLine);

        if (rect.top <= triggerLine) {
            // on préfère ceux déjà entrés dans la zone
            if (distance < bestDistance) {
                bestDistance = distance;
                current = post;
            }
        }
    });

    // fallback si aucun post n'a encore atteint la zone
    if (!current) {
        current = posts[0];
    }

    setActive(current.id);
}

/* ========================= */
/* EVENTS                    */
/* ========================= */

window.addEventListener("scroll", updateActiveFromScroll, {
    passive: true
});

window.addEventListener("resize", updateActiveFromScroll);

updateActiveFromScroll();

/* ========================= */
/* NAV CLICK SMOOTH FOCUS   */
/* ========================= */

links.forEach(link => {
    link.addEventListener("click", (e) => {
        e.preventDefault();

        const target = document.getElementById(link.dataset.target);

        target.scrollIntoView({
            behavior: "smooth",
            block: "start"
        });
    });
});
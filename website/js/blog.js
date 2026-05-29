const posts = document.querySelectorAll(".blog-post");
const links = document.querySelectorAll(".blog-nav a");

function setActive(id) {
    posts.forEach(p => {
        p.classList.toggle("active", p.id === id);
    });

    links.forEach(l => {
        l.classList.toggle("active", l.dataset.target === id);
    });
}

/* ========================= */
/* SCROLL OBSERVER          */
/* ========================= */

const observer = new IntersectionObserver(
    (entries) => {
        entries.forEach(entry => {
            if (entry.intersectionRatio > 0.2) {
                setActive(entry.target.id);
            }
        });
    },
    {
        threshold: [0.1, 0.2, 0.4],
        rootMargin: "-10% 0px -10% 0px"
    }
);

posts.forEach(p => observer.observe(p));

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








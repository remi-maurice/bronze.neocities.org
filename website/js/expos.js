const container = document.getElementById("newsContainer");

let items = [];

/* ========================= */
/* LOAD YAML */
/* ========================= */

fetch("news.yaml")
	.then(res => res.text())
	.then(yamlData => {

		const data = jsyaml.load(yamlData);

		data.news.forEach(category => {

			category.items.forEach(item => {

				const div = document.createElement("div");
				div.classList.add("news-item");

				let date = item.date
					? `<div class="date">${item.date}</div>`
					: "";

				let link = item.lien
					? `<a class="rainbow-text" href="${item.lien}" target="_blank">
						${item.linkText || item.titre_lien || "Lien"} ↗
					</a>`
					: "";

				let desc = item.description || "";

				let img = item.image
					? `<img src="${item.image}" alt="">`
					: "";

				div.innerHTML = `
					${date}
					${link}
					<div class="desc">${desc}</div>
					${img}
				`;

				container.appendChild(div);
			});
		});

		items = document.querySelectorAll(".news-item");
		setActive();
	});

/* ========================= */
/* SCROLL ACTIVE SYSTEM */
/* ========================= */

function setActive() {

	let best = null;
	let bestRatio = 0;

	items.forEach(el => {

		const rect = el.getBoundingClientRect();

		const visible = Math.min(rect.bottom, window.innerHeight) -
		                Math.max(rect.top, 0);

		const ratio = visible / rect.height;

		if (ratio > bestRatio) {
			bestRatio = ratio;
			best = el;
		}
	});

	items.forEach(el => {
		el.classList.toggle("active", el === best);
	});
}

window.addEventListener("scroll", setActive);
window.addEventListener("resize", setActive);


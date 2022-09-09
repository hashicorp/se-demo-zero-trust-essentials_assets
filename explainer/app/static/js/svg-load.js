window.onload = function () {

    const svg_diagram = document.getElementById('svg-diagram');
    const parser = new DOMParser();

    async function fetchSVG() {
        const response = await fetch('/static/img/undraw_happy_music_g6wc.svg');
        const svgText = await response.text();
        const svgDoc = parser.parseFromString(svgText, 'text/xml');
        svg_diagram.appendChild(svgDoc.documentElement);
    }

    fetchSVG();
}

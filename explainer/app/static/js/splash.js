const cells_num = 12
const cells_block = 4
const matrix_size = cells_num * cells_num;
const block_size = cells_block * cells_block;
const matrix_true_size = matrix_size - block_size;
const left_borders = [41, 42, 43, 86, 87, 88];
const right_borders = [40, 41, 42, 85, 86, 87];
const top_borders = [60, 68, 61, 69, 77, 76];
const bottom_borders = [51, 53, 60, 68, 61, 69];

var paths = [
    [
        { id: 61, "type": "line-right" },
        { id: 62, "type": "line-right" },
        { id: 63, "type": "line-right" },
        { id: 64, "type": "line-right" },
        { id: 56, "type": "line-up" },
        { id: 47, "type": "line-up" },
        { id: 35, "type": "line-up" },
        { id: 35, "type": "line-left" },
        { id: 34, "type": "line-left" },
        { id: 33, "type": "line-left" },
        { id: 32, "type": "line-left" },
        { id: 31, "type": "line-left" },
        { id: 30, "type": "line-left" },
        { id: 29, "type": "line-left" },
        { id: 29, "type": "line-down" },
        { id: 41, "type": "line-down" }
    ],

    [
        { id: 69, "type": "line-right" },
        { id: 70, "type": "line-right" },
        { id: 71, "type": "line-right" },
        { id: 63, "type": "line-up" },
        { id: 55, "type": "line-up" },
        { id: 46, "type": "line-up" },
        { id: 34, "type": "line-up" },
        { id: 22, "type": "line-up" },
        { id: 22, "type": "line-left" },
        { id: 21, "type": "line-left" },
        { id: 20, "type": "line-left" },
        { id: 19, "type": "line-left" },
        { id: 18, "type": "line-left" },
        { id: 18, "type": "line-down" },
        { id: 30, "type": "line-down" },
        { id: 42, "type": "line-down" }
    ],

    [
        { id: 77, "type": "line-right" },
        { id: 78, "type": "line-right" },
        { id: 70, "type": "line-up" },
        { id: 62, "type": "line-up" },
        { id: 54, "type": "line-up" },
        { id: 45, "type": "line-up" },
        { id: 33, "type": "line-up" },
        { id: 21, "type": "line-up" },
        { id: 9, "type": "line-up" },
        { id: 9, "type": "line-left" },
        { id: 8, "type": "line-left" },
        { id: 7, "type": "line-left" },
        { id: 7, "type": "line-down" },
        { id: 19, "type": "line-down" },
        { id: 31, "type": "line-down" },
        { id: 43, "type": "line-down" }
    ],

    [
        { id: 76, "type": "line-left" },
        { id: 75, "type": "line-left" },
        { id: 74, "type": "line-left" },
        { id: 73, "type": "line-left" },
        { id: 73, "type": "line-down" },
        { id: 81, "type": "line-down" },
        { id: 93, "type": "line-down" },
        { id: 105, "type": "line-right" },
        { id: 106, "type": "line-right" },
        { id: 107, "type": "line-right" },
        { id: 108, "type": "line-right" },
        { id: 109, "type": "line-right" },
        { id: 110, "type": "line-right" },
        { id: 111, "type": "line-right" },
        { id: 99, "type": "line-up" },
        { id: 87, "type": "line-up" }
    ],

    [
        { id: 68, "type": "line-left" },
        { id: 67, "type": "line-left" },
        { id: 66, "type": "line-left" },
        { id: 66, "type": "line-down" },
        { id: 74, "type": "line-down" },
        { id: 82, "type": "line-down" },
        { id: 94, "type": "line-down" },
        { id: 106, "type": "line-down" },
        { id: 106, "type": "line-right-bottom" },
        { id: 107, "type": "line-right-bottom" },
        { id: 108, "type": "line-right-bottom" },
        { id: 109, "type": "line-right-bottom" },
        { id: 110, "type": "line-right-bottom" },
        { id: 110, "type": "line-up" },
        { id: 98, "type": "line-up" },
        { id: 86, "type": "line-up" }
    ],

    [
        { id: 60, "type": "line-left" },
        { id: 59, "type": "line-left" },
        { id: 59, "type": "line-down" },
        { id: 67, "type": "line-down" },
        { id: 75, "type": "line-down" },
        { id: 83, "type": "line-down" },
        { id: 95, "type": "line-down" },
        { id: 107, "type": "line-down" },
        { id: 119, "type": "line-down" },
        { id: 119, "type": "line-right-bottom" },
        { id: 120, "type": "line-right-bottom" },
        { id: 121, "type": "line-right-bottom" },
        { id: 121, "type": "line-up" },
        { id: 109, "type": "line-up" },
        { id: 97, "type": "line-up" },
        { id: 85, "type": "line-up" }
    ]
];

const parser = new DOMParser();

async function fetchSVG(svg_name, div_target) {
    const response = await fetch(svg_name);
    const svgText = await response.text();
    const svgDoc = parser.parseFromString(svgText, 'text/xml');
    div_target.appendChild(svgDoc.documentElement);
}

window.onload = function () {

    const matrix = document.getElementById("matrix");
    const magic_cell_id = cells_block * cells_num + cells_block;

    for (let i = 0; i < cells_num; i++) {
        for (let j = 0; j < cells_num && (i * cells_num + j <= matrix_true_size); j++) {
            const newDiv = document.createElement("div");

            newDiv.id = i * cells_num + j;
            newDiv.classList.add("cell");
            matrix.appendChild(newDiv);
        }
    }

    document.getElementById(magic_cell_id.toString()).classList.add("cell-span-4");

    svgDiv = document.createElement("div");
    svgDiv.id = "hashicorp-logo";
    fetchSVG("static/img/hashicorp.svg", svgDiv);

    document.getElementById(magic_cell_id.toString()).appendChild(svgDiv)

    paths.forEach(path => {

        path.forEach(function (details, index) {
            const animatedDiv = document.createElement("div");
            animatedDiv.classList.add(details.type);
            animatedDiv.style.cssText += `--splash-delay: ${index + 1}`
            document.getElementById(details.id).appendChild(animatedDiv);
        })

    });

    Promise.all(
        document.getElementById(magic_cell_id.toString()).getAnimations({ subtree: true })
            .map(animation => animation.finished)
    ).then(() => window.location.replace("about"));

}


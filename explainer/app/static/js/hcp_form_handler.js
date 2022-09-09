import { confetti } from './confetti.min.js';

const start = () => {
    setTimeout(function () {
        confetti.start()
    }, 100);
};

//  Stop

const stop = () => {
    setTimeout(function () {
        confetti.stop()
    }, 1000);
};

const onBlur = (e) => {
    if (e.target.value === '') {
        e.target.value = e.target.defaultValue;
    }
}

const onFocus = (e) => {
    e.target.value = '';
}

async function getFormStatus(form_name) {
    const stat_url = `/get_form_status?form_name=${form_name}`
    const response = await fetch(stat_url);
    const jsonbody = await response.json();
    return jsonbody
}

window.onload = function () {
    const hcp_form = document.getElementById("hcp-form");
    const input_divs = [].slice.call(hcp_form.querySelectorAll('input[type="text"]'));

    input_divs.forEach(element => {
        element.addEventListener('focus', onFocus);
        element.addEventListener('blur', onBlur);
    });

    hcp_form.addEventListener('submit', () => {
        localStorage.do_HCP_Confetti = 'true';
    });

    getFormStatus('hcp_form').then(jsonbody => {
        const form_status = jsonbody["ready"];
        const doConfetti = localStorage.do_HCP_Confetti

        if (form_status && doConfetti === 'true') {
            start();
            stop();
            localStorage.do_HCP_Confetti = 'false'
        }
    });

}


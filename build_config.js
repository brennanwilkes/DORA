const fs = require("fs");

const data = fs.readFileSync(process.argv[2]).toString().split("\n");

const minDate = new Date(data.filter(r => r.length > 0).map(r => parseInt(r.split(",")[4])).sort((a,b) => a-b)[0] * 1000 - 1000 * 60 * 60 * 24).toString().split(" ").slice(1,4).join(" ")
const maxDate = new Date().toString().split(" ").slice(1,4).join(" ")

const output = {
	name: "",
	start: minDate,
	end: maxDate,
	results: "",
	repos: data.filter(r => r.length > 0).map(r => r.split(",")).sort((a,b) => parseInt(a[2]) - parseInt(b[2])).map(r => {
		return {
			id: r[0],
			deployment: 0,
			failures: {type: 1},
			weight: parseInt(r[2])
		};
	}),
	scheduler: {},
	workers: []
};
console.log(JSON.stringify(output, null, 4))

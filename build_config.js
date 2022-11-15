const fs = require("fs");

const data = fs.readFileSync(process.argv[2]).toString().split("\n");
const output = {
	name: "",
	start: "",
	end: "",
	results: "",
	repos: data.filter(r => r.length > 0).map(r => r.split(",")).sort((a,b) => parseInt(a[2]) - parseInt(b[2])).map(r => {
		return {
			id: r[0],
			deployment: 1,
			failures: {type: 1},
			weight: parseInt(r[2])
		};
	}),
	scheduler: {},
	workers: []
};
console.log(JSON.stringify(output, null, 4))

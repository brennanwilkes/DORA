const fs = require("fs")
let data = JSON.parse(fs.readFileSync(process.argv[2]));

const scale = "performer";
// const scale = "accelerate";

const format = (label) => {
	if(typeof label === "number"){
		return label;
	}
	if(label === "Elite"){
		return 4;
	}
	if(label === "High"){
		return 3;
	}
	if(label === "Medium"){
		return 2;
	}
	if(label === "Low"){
		return 1;
	}
	return 0;
}

data.results.sort((b,a) => a[scale].score - b[scale].score).forEach((r, i) => {
	if(process.argv[3] === "csv"){
		console.log(`${r.repo},${Object.keys(r[scale]).map(k => {

			if(k === "score"){
				return r[scale][k]
				// const scaled = (r[scale][k] / 8);
				// if(scaled >= 3.25) return "Elite";
				// if(scaled >= 2.25) return "High";
				// if(scaled >= 1.25) return "Medium";
				// if(scaled >= 0.25) return "Low";
				// return "Terrible";
			}
			return `${format(r[scale][k])}`;
		}).join(",")}`);
	}
	else{
		console.log(`${Object.keys(r[scale]).map(k => `${r[scale][k]}`.padEnd(8, " ")).join(" | ")} | ${r.repo}`);
	}
});

const rows = require("fs").readFileSync(0, "utf-8").split("\n").filter(r => r.length > 0);
const data = rows.map((row,i) => {
	const tag = row.match(/v[0-9]+\.[0-9]+\.[0-9]+/)?.[0];
	let major,minor,patch;
	if(!tag){
		major = undefined;
		minor = undefined;
		patch = undefined;
	}
	else{
		const numerical = tag.replace(/v/, "");
		major = parseInt(numerical.split(".")[0]);
		minor = parseInt(numerical.split(".")[1]);
		patch = parseInt(numerical.split(".")[2]);
	}


	return {
		row,
		major,
		minor,
		patch,
		index: i
	}
});

data.sort((a, b) => {
	return a.major - b.major ||
		a.minor - b.minor ||
		a.patch - b.patch ||
		a.index - b.index ||
		a.row.localCompare(b.row);
}).map(row => row.row).forEach((item, i) => {
	console.log(item)
});

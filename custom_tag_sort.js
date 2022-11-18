const exec = require("util").promisify(require("child_process").exec);
const rows = require("fs").readFileSync(0, "utf-8").split("\n").filter(r => r.length > 0);

const START = new Date(process.argv[2]).getTime() / 1000;
const END = new Date(process.argv[3]).getTime() / 1000;

Promise.all(rows.map(async (row,i) => {
	const tag = row.match(/v?[0-9]+\.[0-9]+(\.[0-9]+)?/)?.[0];
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
	const time = (await exec(`date -d "$( git log -1 --format=%ai ${row} )" +%s`)).stdout;

	if(time < START || time > END){
		return undefined;
	}

	return {
		row,
		major,
		minor,
		patch,
		index: i
	}
})).then(data => {
	data.filter(d => !!d).sort((a, b) => {
		let aPatch = a.patch;
		let bPatch = b.patch;
		if(aPatch && !bPatch){
			bPatch = 0;
		}
		if(bPatch && !aPatch){
			aPatch = 0;
		}
		return (a.major - b.major) ||
			(a.minor - b.minor) ||
			(aPatch - bPatch) ||
			(a.index - b.index) ||
			a.row.localCompare(b.row);
	}).map(row => row.row).forEach((item, i) => {
		console.log(item)
	});
});

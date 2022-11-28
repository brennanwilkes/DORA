const fs = require("fs")
let data = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 1]));
console.log(`repo,deploymentFrequency,leadTimeForChanges,meanTimeToRecover,changeFailureRate`)
data.results.map(r => ({
	repo: r.repo,
	data: r[-1]
})).forEach((r, i) => {
	console.log(`${r.repo},${r.data.deploymentFrequency},${r.data.leadTimeForChanges},${r.data.meanTimeToRecover},${r.data.changeFailureRate}`)
});

const deploymentFrequency = data.results.map(r => r[-1].deploymentFrequency[0]);
const leadTimeForChanges = data.results.map(r => r[-1].leadTimeForChanges[0]);
const meanTimeToRecover = data.results.map(r => r[-1].meanTimeToRecover[0]);
const changeFailureRate = data.results.map(r => r[-1].changeFailureRate[0]);
// console.log(deploymentFrequency.filter(d => d/365 > 1).length)
// console.log(deploymentFrequency.filter(d => d/365*7/2 > 1).length)
// console.log(deploymentFrequency.filter(d => d/365*7 > 1).length)
// console.log(deploymentFrequency.filter(d => d/12 > 1).length)
// console.log(deploymentFrequency.filter(d => d > 1).length)


// const divide = (data, buckets) => {
// 	let bins = [];
// 	buckets.forEach((b, i) => {
// 		bins = [...bins, []];
// 	});
// 	data.forEach((d, i) => {
// 		buckets.forEach((b, j) => {
// 			if(d > b[0] && d <= b[1]){
// 				bins[j] = [...bins[j], d];
// 			}
// 		});
// 	});
// 	return bins;
// }
//
// const average = (data) => data.reduce((acc, nxt) => acc + nxt, 0) / data.length;
//
// const variance = (data) => {
// 	const avg = average(data);
// 	return data.reduce((acc, nxt) => acc + Math.pow(nxt - avg, 2), 0) / data.length;
// }
//
// const boundriesToBuckets = (bins) => {
// 	const min = 0;
// 	const max = 100000000000000000;
// 	return [...(bins.map((b, i) => {
// 		if(i === 0) return [min, b]
// 		return [bins[i - 1], b];
// 	})), [bins[bins.length - 1], max]];
// }
//
// const dataset = deploymentFrequency.sort((a,b) => a - b);
// const MIN = dataset[0] - 1;
// const MAX = dataset[dataset.length - 1] + 1;
//
// let optimal = undefined;
// let vOptimal = 1000000000000000000000;
//
// for (let i = MIN; i < MAX / 4; i+=1) {
// 	for (let k = MAX / 2; k < MAX; k+=10) {
// 		for (let j = i + 10; j < k - 10; j+=5) {
// 			const buckets = [i,j,k];
// 			const v = average(divide(dataset, boundriesToBuckets(buckets)).map(variance));
// 			if(!isNaN(v)){
// 				if(v < vOptimal){
// 					vOptimal = v;
// 					optimal = buckets;
// 				}
// 			}
// 		}
// 	}
// }
// console.log(optimal);
// console.log(vOptimal);
// console.log(variance(divide(dataset, boundriesToBuckets(optimal)).map(variance)));
// // console.log(variance(divide(deploymentFrequency, boundriesToBuckets(buckets)).map(variance)))

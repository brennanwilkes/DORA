import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros} from "../utils.js";

function MeanTimeToRecover(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	// const time = "resolved";
	const time = "created"
	let firstNonNull = labels.length - 1; for(;firstNonNull >= 0 && props.data.results.some(r => r[`${props.scale}`].meanTimeToRecover[firstNonNull] !== null); firstNonNull-- ){}; firstNonNull+=1

	const data = {
		labels: labels.slice(firstNonNull),
		datasets: props.data.results.map((result, i) => ({
			label: result.repo,
			fill: true,
			data: result[`${props.scale}`].meanTimeToRecover.map(d => d === null ? null : Math.max(0, d)).slice(firstNonNull),
			backgroundColor: props.style === "line" ? COLOURS_SEMI_TRANS[i] : COLOURS[i],
			borderColor: COLOURS[i]
		}))
	};

	if(props.scale === -1){
		data.datasets = data.datasets.sort((a,b) => a.data[0] - b.data[0]);
	}
	if(props.debug){
		data.datasets = data.datasets.filter((_, i) => i < 5 || i > data.datasets.length - 5);
	}

	const options = makeOptions("Mean Time To Recover", "Average Days Between Issue and Fix");
	if(props.style === "line"){
		return (<Line options={options} data={data} />);
	}
	return (<Bar options={options} data={data} />);
}

export default MeanTimeToRecover;

import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros, getScaleLabel, YEAR} from "../utils.js";

function DeploymentFrequency(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	let firstNonNull = labels.length - 1; for(;firstNonNull >= 0 && props.data.results.some(r => r[`${props.scale}`].deploymentFrequency[firstNonNull] !== null); firstNonNull-- ){}; firstNonNull+=1
	const data = {
		labels: labels.slice(firstNonNull),
		datasets: props.data.results.map((result, i) => ({
			label: result.repo,
			fill: result.repo !== "Trendline",
			data: result[`${props.scale}`].deploymentFrequency.slice(firstNonNull),
			backgroundColor: props.style === "line" ? COLOURS_SEMI_TRANS[i] : COLOURS[i],
			borderColor: COLOURS[result.repo === "Trendline" ? i - 1 : i],
			borderDash: result.repo === "Trendline" ? [25, 25] : undefined
		}))
	};

	if(props.scale === -1){
		data.datasets = data.datasets.sort((a,b) => a.data[0] - b.data[0]);
	}

	if(props.debug){
		data.datasets = data.datasets.filter((_, i) => i < 5 || i > data.datasets.length - 5);
	}

	const options = makeOptions("Deployment Frequency", `Deployments Per ${props.scale === -1 ? "Year" : getScaleLabel(props.scale)}`, props.debug || props.data.results[0].repo === "Average");
	if(props.style === "line"){
		return (<Line options={options} data={data} />);
	}
	return (<Bar options={options} data={data} />);
}

export default DeploymentFrequency;

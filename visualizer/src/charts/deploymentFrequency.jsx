import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros, getScaleLabel, YEAR} from "../utils.js";

function DeploymentFrequency(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);


	const data = {
		labels,
		datasets: props.data.results.map((result, i) => ({
			label: result.repo,
			fill: true,
			data: dates.map(d => Object.keys(result.deployments).map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - props.scale) || props.scale === -1 ).length).map(d => {
				if(props.scale === -1 && Object.keys(result.deployments).length > 2){
					const sorted = Object.keys(result.deployments).map(k => result.deployments[k]).sort((a,b) => a.date - b.date);
					const start = sorted[0].date;
					const end = sorted[sorted.length - 1].date;
					return d / (end - start) * YEAR / 1000
				}
				return d;
			}).map(removeLeadingZeros),
			backgroundColor: props.style === "line" ? COLOURS_SEMI_TRANS[i] : COLOURS[i],
			borderColor: COLOURS[i]
		}))
	};

	const options = makeOptions("Deployment Frequency", `Deployments Per ${props.scale === -1 ? "Year" : getScaleLabel(props.scale)}`);
	if(props.style === "line"){
		return (<Line options={options} data={data} />);
	}
	return (<Bar options={options} data={data} />);
}

export default DeploymentFrequency;

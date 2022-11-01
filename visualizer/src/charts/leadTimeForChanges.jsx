import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions} from "../utils.js";

function LeadTimeForChanges(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	const data = {
		labels,
		datasets: props.data.results.map((result, i) => ({
			label: result.repo,
			fill: true,
			data: dates.map(d => {
				const versions = Object.keys(result.deployments);
				const deployments = versions.map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - props.scale) || props.scale === -1 )
				let sum = 0;
				let n = 0;
				deployments.forEach((deployment, i) => {
					sum += deployment.totalDelta;
					n += deployment.commits.length;
				});
				if(n === 0){
					return 0;
				}
				return sum / n / 60 / 60 / 24;

			}),
			backgroundColor: props.style === "line" ? COLOURS_SEMI_TRANS[i] : COLOURS[i],
			borderColor: COLOURS[i]
		}))
	};

	const options = makeOptions("Lead Time For Changes", "Average Days Between Commit and Deployment");
	if(props.style === "line"){
		return (<Line options={options} data={data} />);
	}
	return (<Bar options={options} data={data} />);
}

export default LeadTimeForChanges;

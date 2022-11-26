import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros, getColourIndex} from "../utils.js";

function LeadTimeForChanges(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	let firstNonNull = labels.length - 1; for(;firstNonNull >= 0 && props.data.results.some(r => r[`${props.scale}`].leadTimeForChanges[firstNonNull] !== null); firstNonNull-- ){}; firstNonNull+=1
	const data = {
		labels: labels.slice(firstNonNull),
		datasets: props.data.results.map((result, i) => {
			const colourIndex = props.colour ? getColourIndex(result.performer?.leadTimeForChanges) : i;
			return {
				label: result.repo,
				fill: result.repo !== "Average Trendline",
				data: result[`${props.scale}`].leadTimeForChanges.map(d => d === null ? null : Math.max(0, d)).slice(firstNonNull),
				backgroundColor: props.style === "line" ? COLOURS_SEMI_TRANS[colourIndex] : COLOURS[colourIndex],
				borderColor: COLOURS[colourIndex],
				borderDash: result.repo === "Average Trendline" ? [25, 25] : undefined
			}
		})
	};

	if(props.scale === -1){
		data.datasets = data.datasets.sort((a,b) => a.data[0] - b.data[0]);
	}
	if(props.debug){
		data.datasets = data.datasets.filter((_, i) => i < props.debug || i > data.datasets.length - props.debug);
	}

	const options = makeOptions("Lead Time For Changes", "Average Days Between Commit and Deployment", props.debug || props.data.results[0].repo === "Average");
	if(props.style === "line"){
		return (<Line options={options} data={data} />);
	}
	return (<Bar options={options} data={data} />);
}

export default LeadTimeForChanges;

import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros} from "../utils.js";

function LeadTimeForChanges(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	const data = {
		labels,
		datasets: props.data.results.map((result, i) => ({
			label: result.repo,
			fill: true,
			data: result[`${props.scale}`].leadTimeForChanges.map(d => Math.max(0, d)),
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

import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros} from "../utils.js";

function MeanTimeToRecover(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	// const time = "resolved";
	const time = "created"

	const data = {
		labels,
		datasets: props.data.results.map((result, i) => ({
			label: result.repo,
			fill: true,
			data: dates.map(d => {
				const failures = result.failures.filter(fail => (fail[time] * 1000 < d && fail[time] * 1000 > d - props.scale) || props.scale === -1 )
				let sum = 0;
				let n = 0;
				failures.forEach((fail, i) => {
					sum += (fail.resolved - fail.created);
					n += 1;
				});
				if(n === 0){
					return 0;
				}
				return sum / n / 60 / 60 / 24;

			}).map(removeLeadingZeros),
			backgroundColor: props.style === "line" ? COLOURS_SEMI_TRANS[i] : COLOURS[i],
			borderColor: COLOURS[i]
		}))
	};

	const options = makeOptions("Mean Time To Recover", "Average Days Between Issue and Fix");
	if(props.style === "line"){
		return (<Line options={options} data={data} />);
	}
	return (<Bar options={options} data={data} />);
}

export default MeanTimeToRecover;

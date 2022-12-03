import { useState } from 'react'
import { Bar, Line } from 'react-chartjs-2';
import zoomPlugin from 'chartjs-plugin-zoom';
import {COLOURS, COLOURS_SEMI_TRANS, divideTimes, makeOptions, removeLeadingZeros, getColourIndex} from "../utils.js";

function ChangeFailureRate(props) {
	const [dates, labels] = divideTimes(new Date(props.data.start), new Date(props.data.end), props.scale);

	let firstNonNull = labels.length - 1; for(;firstNonNull >= 0 && (
		props.data.results.some(r => r[`${props.scale}`].changeFailureRate[firstNonNull] !== null &&
		props.data.results.some(r => r[`${props.scale}`].changeFailureRate[firstNonNull] !== undefined &&
		r.repo !== "Average Trendline" && r.repo !== "Average"
	))); firstNonNull-- ){}; firstNonNull+=1
	const data = {
		labels: labels.slice(firstNonNull),
		datasets: props.data.results.map((result, i) => {
			let colourIndex = props.colour ? getColourIndex(result[props.accelerate ? "accelerate" : "performer"]?.changeFailureRate) : i;
			if(props.gradient && props.data.results[0].repo !== "Average"){
				colourIndex = `g${result[props.accelerate ? "accelerate" : "performer"].score}`
			}
			return {
				label: result.repo,
				fill: result.repo !== "Average Trendline",
				data: result[`${props.scale}`].changeFailureRate.slice(firstNonNull),
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
	const options = makeOptions("Change Failure Rate", "Percentage Of Deployments With A Failure", props.debug || props.data.results[0].repo === "Average");
	if(props.style === "line"){
		return (<Line plugins={[zoomPlugin]} options={options} data={data} />);
	}
	return (<Bar plugins={[zoomPlugin]} options={options} data={data} />);
}

export default ChangeFailureRate;

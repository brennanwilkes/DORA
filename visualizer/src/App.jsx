import { useState, useEffect } from 'react'
import './App.css'
import {
	Chart as ChartJS,
	CategoryScale,
	LinearScale,
	BarElement,
	Title,
	Tooltip,
	Legend,
	PointElement,
	LineElement,
	Filler
} from 'chart.js';
import { Bar } from 'react-chartjs-2';
// import brnkl from "./data/brnkl-minified.json"
// import combined from "./data/combined-minified.json"
import paper from "./data/paper4b-minified.json"
// import python from "./data/python-minified.json"

import DeploymentFrequency from "./charts/deploymentFrequency";
import LeadTimeForChanges from "./charts/leadTimeForChanges";
import MeanTimeToRecover from "./charts/meanTimeToRecover";
import ChangeFailureRate from "./charts/changeFailureRate";
import {DAY, WEEK, MONTH, MONTH4, MONTH6, YEAR, getScaleLabel} from "./utils";
import Slider from "@mui/material/Slider";
import {GraphStyleSwitch, AverageSwitch} from "./components/Switch";
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';

ChartJS.register(
	CategoryScale,
	LinearScale,
	BarElement,
	Title,
	Tooltip,
	Legend,
	PointElement,
	LineElement,
	Filler
);

// combined.results = combined.results.filter(r => r.repo !== "kubernetes/kubernetes")
paper.results = paper.results.filter(r => (
	r.repo !== "ethereum/go-ethereum"
))
// paper.results = paper.results.filter(r => r.repo === "ethereum/go-ethereum")
// paper.results = paper.results.filter(r => r.repo === "python/cpython")
const staticDataset = paper;

function App() {

	const [scale, setScale] = useState(6);
	const [metric, setMetric] = useState(0);
	const [barChart, setBarChart] = useState(true);
	const [average, setAverage] = useState(false);
	const [dataset, setDataset] = useState(staticDataset);
	const debug = false;

	useEffect(() => {
		if(average){
			const avg = {};
			staticDataset.results.forEach((result, i) => {
				Object.keys(result).forEach((key, i) => {
					if(key === "repo"){
						return;
					}
					if(!avg[key]){
						avg[key] = {
							changeFailureRate: [],
							deploymentFrequency: [],
							leadTimeForChanges: [],
							meanTimeToRecover: []
						}
					}
					Object.keys(result[key]).forEach((met, i) => {
						result[key][met].forEach((datapoint, i) => {
							if(!avg[key][met][i]){
								avg[key][met][i] = {
									total: 0,
									count: 0
								}
							}
							if(datapoint !== null){
								avg[key][met][i] = {
									total: avg[key][met][i].total + datapoint,
									count: avg[key][met][i].count + 1
								}
							}
						});
					});

				});
			});
			Object.keys(avg).forEach((key, i) => {
				Object.keys(avg[key]).forEach((met, i) => {
					avg[key][met] = avg[key][met].map(d => (d.total / (d.count || 1)))
				});
			});
			setDataset({
				...staticDataset,
				results: [{...avg, repo: "Averge"}]
			});
		}
		else{
			setDataset(staticDataset);
		}
	}, [average]);



	return (
		<div>
			<div style={{
				position: "absolute",
				width: "90vw",
				left: "5vw",
				top: "2.5vh",
				overflow: "visible",
				display: "flex",
				alignItems: "center",
				justifyContent: "center"
			}}>
				<Tabs onChange={(e, val) => {
					setMetric(val);
				}} value={metric} >
					<Tab label="DeploymentFrequency" value={0} />
					<Tab label="Lead Time For Changes" value={1} />
					<Tab label="Mean Time To Recover" value={2} />
					<Tab label="Change Failure Rate" value={3} />
				</Tabs>

			</div>

			<Slider
				sx={{
					position: "absolute",
					width: "40vw",
					left: "5vw",
					top: "10vh",
					overflow: "visible"
				}}
				aria-label="Custom marks"
				value={scale}
				onChange={e => {
					setScale(e.target.value);
				}}
				step={null}
				valueLabelFormat={val => {
					return getScaleLabel([DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][val])
				}}
				min={3}
				max={7}
				valueLabelDisplay="auto"
				marks={[
					{value: 0, label: "Day"},
					{value: 1, label: "Week"},
					{value: 2, label: "Month"},
					{value: 3, label: "Four Months"},
					{value: 4, label: "Six Months"},
					{value: 5, label: "Year"},
					{value: 6, label: "Total"},
					{value: 7, label: "Project Lifecycle"}
				]}
			/>
			<div style={{
				position: "absolute",
				width: "40vw",
				right: "5vw",
				top: "10vh",
				overflow: "visible",
				display: "flex",
				alignItems: "center",
				justifyContent: "center"
			}}>
				<GraphStyleSwitch value={barChart} onChange={(e) => setBarChart(e.target.checked)} />
				<AverageSwitch value={average} onChange={(e) => setAverage(e.target.checked)} />
			</div>

			<div id="chart">{
				metric === 0 ? (
					<DeploymentFrequency debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				) : (metric === 1 ? (
					<LeadTimeForChanges debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				) : (metric === 2 ? (
					<MeanTimeToRecover debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				) : (
					<ChangeFailureRate debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				)))
			}</div>
		</div>
	)
}

export default App

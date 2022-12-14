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
import paper from "./data/paper5-minified.json"
// import paper from "./data/paper4b-minified.json"
// import python from "./data/python-minified.json"

import DeploymentFrequency from "./charts/deploymentFrequency";
import LeadTimeForChanges from "./charts/leadTimeForChanges";
import MeanTimeToRecover from "./charts/meanTimeToRecover";
import ChangeFailureRate from "./charts/changeFailureRate";
import {DAY, WEEK, MONTH, MONTH4, MONTH6, YEAR, getScaleLabel, removeLeadingZeros} from "./utils";
import Slider from "@mui/material/Slider";
import {GraphStyleSwitch, AverageSwitch, CheckSwitch} from "./components/Switch";
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import Typography from '@mui/material/Typography';

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
// paper.results = paper.results.filter(r => (
// 	r.repo !== "ethereum/go-ethereum"
// ))
// paper.results = paper.results.filter(r => r.repo === "ethereum/go-ethereum")
// paper.results = paper.results.filter(r => r.repo === "python/cpython")
const staticDataset = paper;

function App() {

	const [scale, setScale] = useState(6);
	const [metric, setMetric] = useState(0);
	const [barChart, setBarChart] = useState(true);
	const [average, setAverage] = useState(false);
	const [colour, setColour] = useState(true);
	const [accelerate, setAccelerate] = useState(true);
	const [dataset, setDataset] = useState(staticDataset);
	const [gradient, setGradient] = useState(false);
	const debug = 0;

	useEffect(() => {
		if(average){
			const avg = {
				avg: {},
				Elite: {},
				High: {},
				Medium: {},
				Low: {},
				Terrible: {}
			};
			const moving = {
				avg: {},
				Elite: {},
				High: {},
				Medium: {},
				Low: {},
				Terrible: {}
			}
			staticDataset.results.forEach((result, i) => {
				Object.keys(result).forEach((key, i) => {
					if(key === "repo" || key ==="performer" || key === "accelerate"){
						return;
					}
					Object.keys(avg).forEach((performer) => {
						if(!avg[performer][key]){
							avg[performer][key] = {
								changeFailureRate: [],
								deploymentFrequency: [],
								leadTimeForChanges: [],
								meanTimeToRecover: []
							}
							moving[performer][key] = {
								changeFailureRate: [],
								deploymentFrequency: [],
								leadTimeForChanges: [],
								meanTimeToRecover: []
							}
						}
					});

					Object.keys(result[key]).forEach((met, i) => {
						result[key][met].forEach((datapoint, i) => {
							Object.keys(avg).forEach((performer) => {
								if(!avg[performer][key][met][i]){
									avg[performer][key][met][i] = {
										total: 0,
										count: 0
									}
								}
							});
							if(datapoint !== null){
								const performer = result[accelerate ? "accelerate" : "performer"][met];
								avg[performer][key][met][i] = {
									total: avg[performer][key][met][i].total + datapoint,
									count: avg[performer][key][met][i].count + 1
								}
								avg.avg[key][met][i] = {
									total: avg.avg[key][met][i].total + datapoint,
									count: avg.avg[key][met][i].count + 1
								}
							}
						});
					});

				});
			});
			Object.keys(avg).forEach((performer, i) => {
				Object.keys(avg[performer]).forEach((key, i) => {
					Object.keys(avg[performer][key]).forEach((met, i) => {
						avg[performer][key][met] = avg[performer][key][met].map(d => (d.total / (d.count || 1)))
						moving[performer][key][met] = avg[performer][key][met].map((d,i,arr) => {
							const M = 7;
							let total = 0;
							let count = 0;
							for (let j = Math.max(0, i - M); j < Math.min(i + M, arr.length); j++){
								total += arr[j];
								count += 1;
							}
							return (total / (count || 1));
						});
					});
				});
			});
			let avgResults = Object.keys(avg).map(performer => ({
				...(avg[performer]),
				repo: performer === "avg" ? "Average" : performer,
				performer: {
					deploymentFrequency: performer,
					leadTimeForChanges: performer,
					meanTimeToRecover: performer,
					changeFailureRate: performer
				},
				accelerate: {
					deploymentFrequency: performer,
					leadTimeForChanges: performer,
					meanTimeToRecover: performer,
					changeFailureRate: performer
				}
			}));
			if(!barChart){
				avgResults = [...avgResults, {...(moving.avg), repo: "Average Trendline"}];
			}
			avgResults.forEach((r, i) => {
				Object.keys(r).forEach((k, i) => {
					if(k !== "repo" && k!== "performer" && k!=="accelerate"){
						Object.keys(r[k]).forEach((m, i) => {
							r[k][m] = r[k][m].map(removeLeadingZeros);
						});
					}
				});
			});

			setDataset({
				...staticDataset,
				results: avgResults
			});
		}
		else{
			setDataset(staticDataset);
		}
	}, [average, barChart, accelerate]);

	return (
		<div>
			<div id="stats" style={{
				position: "absolute",
				top: "2vh",
				left: "80vw",
				width: "25vw",
				display: "flex",
				flexDirection: "row",
				alignItems: "start",
				justifyContent: "start",
				textAlign: "left"
			}}>
				<div>
					<Typography>Repos: {staticDataset.repos}</Typography>
					<Typography>Deployments: {Math.round(staticDataset.deployments / 100) / 10}k</Typography>
				</div>
				<div>
					<Typography>Commits: {Math.round(staticDataset.commits / 100000) / 10}m</Typography>
					<Typography>Failures: {Math.round(staticDataset.failures / 100) / 10}k</Typography>
				</div>
			</div>
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
					width: "35vw",
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
				width: "45vw",
				right: "5vw",
				top: "10vh",
				overflow: "visible",
				display: "flex",
				alignItems: "center",
				justifyContent: "center"
			}}>
				<GraphStyleSwitch value={barChart} onChange={(e) => setBarChart(e.target.checked)} />
				<CheckSwitch value={average} label="Group By Performance" onChange={(e) => setAverage(e.target.checked)} />
				<CheckSwitch value={!average} label="Custom Goalposts" onChange={(e) => setAccelerate(!e.target.checked)} />
				<CheckSwitch value={gradient} label="Performance Gradient" onChange={(e) => setGradient(e.target.checked)} />
			</div>

			<div id="chart">{
				metric === 0 ? (
					<DeploymentFrequency gradient={gradient} accelerate={accelerate} colour={colour} debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				) : (metric === 1 ? (
					<LeadTimeForChanges gradient={gradient} accelerate={accelerate} colour={colour} debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				) : (metric === 2 ? (
					<MeanTimeToRecover gradient={gradient} accelerate={accelerate} colour={colour} debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				) : (
					<ChangeFailureRate gradient={gradient} accelerate={accelerate} colour={colour} debug={debug} data={dataset} style={barChart ? "bar" : "line"} scale={[DAY,WEEK,MONTH,MONTH4,MONTH6,YEAR, -1, -2][scale]} />
				)))
			}</div>
		</div>
	)
}

export default App

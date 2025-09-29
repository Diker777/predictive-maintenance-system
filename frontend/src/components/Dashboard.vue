<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import * as echarts from 'echarts'
import axios from 'axios'
import * as signalR from '@microsoft/signalr'

type MetricType = 1 | 2 | 3
interface Device { id: string; name: string; description?: string }
interface SensorReading { id: string; deviceId: string; metric: MetricType; value: number; timestampUtc: string }
interface ThresholdRule { id: string; deviceId: string; metric: MetricType; operator: number; minValue?: number; maxValue?: number; enabled: boolean; severity: number }
interface Alert { id: string; deviceId: string; metric: MetricType; value: number; message: string; severity: number; createdUtc: string; acknowledged: boolean }

const apiBase = ref<string>(import.meta.env.VITE_API_BASE || 'http://localhost:5219')
const hubBase = ref<string>(apiBase.value)

const devices = ref<Device[]>([])
const selectedDeviceId = ref<string>('')
const alerts = ref<Alert[]>([])
const rules = ref<ThresholdRule[]>([])

const metric = ref<MetricType>(1)
const chartEl = ref<HTMLDivElement | null>(null)
const ringEl = ref<HTMLDivElement | null>(null)
const donutEl = ref<HTMLDivElement | null>(null)
const barEl = ref<HTMLDivElement | null>(null)
const trendEl = ref<HTMLDivElement | null>(null)
const trendChartsEl = ref<HTMLDivElement | null>(null)
let chart: echarts.ECharts | null = null
let ringChart: echarts.ECharts | null = null
let donutChart: echarts.ECharts | null = null
let barChart: echarts.ECharts | null = null
let trendChart: echarts.ECharts | null = null
let trendChartsChart: echarts.ECharts | null = null

// extra series data for big-screen view
const torqueData = ref<SensorReading[]>([])
const speedData = ref<SensorReading[]>([])

// realtime axis data for combined display
const realtimeAxisData = ref<Array<{axisName: string, time: string, torque: string, speed: string, status: string}>>([])

// cylinder stroke time data
const cylinderStrokeData = ref<Array<{cylinderName: string, time: string, strokeTime: string, status: string}>>([])

const metricName = computed(() => ({1: 'CylinderStrokeTime', 2: 'ShaftTorque', 3: 'Speed'} as Record<number, string>)[metric.value])

const kpiStrokeAvg = computed(() => avgFrom(metric.value === 1 ? [] : [], torqueData.value, speedData.value, 1))
const kpiTorqueAvg = computed(() => avgFrom([], torqueData.value, [], 2))
const kpiSpeedAvg = computed(() => avgFrom([], [], speedData.value, 3))

// completion rate estimate using current metric rules
const completionRate = computed(() => {
  const currentRules = rules.value.filter(r => r.metric === metric.value && r.enabled)
  const data = chartLastData.value
  if (!data.length || !currentRules.length) return 0
  let ok = 0
  for (const r of data) {
    const triggered = currentRules.some(rule => {
      const v = r.value
      switch (rule.operator) {
        case 1: return v > (rule.maxValue ?? Number.MAX_VALUE)
        case 2: return v >= (rule.maxValue ?? Number.MAX_VALUE)
        case 3: return v < (rule.minValue ?? -Number.MAX_VALUE)
        case 4: return v <= (rule.minValue ?? -Number.MAX_VALUE)
        case 5: return !(v >= (rule.minValue ?? -Number.MAX_VALUE) && v <= (rule.maxValue ?? Number.MAX_VALUE))
        default: return false
      }
    })
    if (!triggered) ok++
  }
  return Math.round((ok / data.length) * 10000) / 100
})

const chartLastData = ref<SensorReading[]>([])

// DataV configs (removed unused configs)

// const capsuleConfig = computed(() => {
//   const items: Array<{ name: string; value: number }> = [
//     { name: 'Cylinder', value: chartLastData.value.length },
//     { name: 'Torque', value: torqueData.value.length },
//     { name: 'Speed', value: speedData.value.length }
//   ]
//   return {
//     data: items,
//     colors: ['#2cf3ff', '#50e3c2', '#f5a623']
//   }
// })

function avgFrom(_a: SensorReading[], torque: SensorReading[], speed: SensorReading[], pick: MetricType) {
  const arr = pick === 2 ? torque : pick === 3 ? speed : []
  if (!arr.length) return 0
  return arr.reduce((s, r) => s + r.value, 0) / arr.length
}

async function fetchDevices() {
  const res = await axios.get<Device[]>(`${apiBase.value}/api/devices`)
  devices.value = res.data
  if (!selectedDeviceId.value) {
    const first = devices.value?.[0]
    if (first) selectedDeviceId.value = first.id
  }
}

async function fetchRules() {
  if (!selectedDeviceId.value) return
  const res = await axios.get<ThresholdRule[]>(`${apiBase.value}/api/thresholds`, { params: { deviceId: selectedDeviceId.value } })
  rules.value = res.data
}

async function fetchReadingsFor(metricParam: MetricType) {
  if (!selectedDeviceId.value) return [] as SensorReading[]
  const res = await axios.get<SensorReading[]>(`${apiBase.value}/api/readings`, {
    params: { deviceId: selectedDeviceId.value, metric: metricParam }
  })
  return res.data
}

async function refreshCharts() {
  const data = await fetchReadingsFor(metric.value)
  chartLastData.value = data
  renderMainChart(data)
  renderRingChart()
  renderTrendChart()
  renderTrendChartsView()
}

async function refreshSideSeries() {
  torqueData.value = await fetchReadingsFor(2)
  speedData.value = await fetchReadingsFor(3)
  updateRealtimeAxisData()
  updateCylinderStrokeData()
}

function updateRealtimeAxisData() {
  // 模拟从SQL Server数据库读取的多个轴实时数据
  const axisNames = [
    '主轴A1', '主轴A2', '主轴B1', '主轴B2', '主轴C1', '主轴C2',
    '辅助轴D1', '辅助轴D2', '进给轴X', '进给轴Y', '进给轴Z',
    '回转轴A', '回转轴B', '回转轴C', '冷却轴P1', '冷却轴P2',
    '液压轴H1', '液压轴H2', '传动轴T1', '传动轴T2', '驱动轴M1',
    '驱动轴M2', '控制轴S1', '控制轴S2', '监测轴V1', '监测轴V2'
  ]
  const now = new Date()
  
  realtimeAxisData.value = axisNames.map((axisName, index) => {
    // 模拟SQL Server数据库中的实时轴数据
    // 扭矩范围: 20-120 Nm，速度范围: 50-300 rpm
    const baseTorque = 40 + (index % 5) * 15
    const baseSpeed = 80 + (index % 7) * 30
    
    const simulatedTorque = baseTorque + Math.sin(Date.now() / 1000 + index) * 10 + Math.random() * 8
    const simulatedSpeed = baseSpeed + Math.cos(Date.now() / 1500 + index) * 20 + Math.random() * 12
    
    const torqueValue = Math.max(0, simulatedTorque)
    const speedValue = Math.max(0, simulatedSpeed)
    
    // 根据阈值判断状态
    // 扭矩阈值: > 80 警告, 速度阈值: > 200 警告
    const torqueStatus = torqueValue > 80 ? '警告' : '正常'
    const speedStatus = speedValue > 200 ? '警告' : '正常'
    const overallStatus = (torqueStatus === '警告' || speedStatus === '警告') ? '警告' : '正常'
    
    return {
      axisName,
      time: new Date(now.getTime() - (index * 500) - Math.random() * 2000).toLocaleTimeString(),
      torque: torqueValue.toFixed(1),
      speed: speedValue.toFixed(1),
      status: overallStatus
    }
  })
}

function renderMainChart(data: SensorReading[]) {
  if (!chartEl.value) return
  if (!chart) {
    chart = echarts.init(chartEl.value)
    window.addEventListener('resize', () => chart && chart.resize())
  }
  const sorted = [...data].sort((a,b) => new Date(a.timestampUtc).getTime() - new Date(b.timestampUtc).getTime())
  chart.setOption({
    backgroundColor: 'transparent',
    title: { text: `${metricName.value} Trend`, textStyle: { color: '#93dcfe' } },
    tooltip: { trigger: 'axis' },
    grid: { left: 40, right: 20, top: 40, bottom: 40 },
    xAxis: { type: 'time', axisLine: { lineStyle: { color: '#6ea1c5' } }, axisLabel: { color: '#cfe8ff' } },
    yAxis: { type: 'value', axisLine: { lineStyle: { color: '#6ea1c5' } }, axisLabel: { color: '#cfe8ff' }, splitLine: { lineStyle: { color: '#1a3b5a' } } },
    series: [
      {
        type: 'line',
        smooth: true,
        showSymbol: false,
        lineStyle: { width: 2, color: '#2cf3ff' },
        areaStyle: { color: 'rgba(44,243,255,0.12)' },
        data: sorted.map(r => [r.timestampUtc, r.value])
      }
    ]
  })
}

function renderRingChart() {
  if (!ringEl.value) return
  if (!ringChart) {
    ringChart = echarts.init(ringEl.value)
    window.addEventListener('resize', () => ringChart && ringChart.resize())
  }
  const rate = completionRate.value
  ringChart.setOption({
    backgroundColor: 'transparent',
    series: [
      {
        type: 'pie',
        radius: ['70%', '88%'],
        silent: true,
        label: { show: false },
        data: [
          { value: rate, itemStyle: { color: '#2cf3ff' } },
          { value: Math.max(0, 100 - rate), itemStyle: { color: '#0b2d4c' } }
        ]
      }
    ],
    graphic: [
      { type: 'text', left: 'center', top: '40%', style: { text: rate.toFixed(2) + '%', fill: '#2cf3ff', fontSize: 34, fontWeight: 700 } },
      { type: 'text', left: 'center', top: '58%', style: { text: '完成率', fill: '#93dcfe', fontSize: 14 } }
    ]
  })
}

function renderDonutChart() {
  if (!donutEl.value) return
  if (!donutChart) {
    donutChart = echarts.init(donutEl.value)
    window.addEventListener('resize', () => donutChart && donutChart.resize())
  }
  const recent = alerts.value.slice(0, 100)
  const buckets = { 正常: 0, 预警: 0, 告警: 0, 严重: 0 }
  for (const a of recent) {
    if (a.severity <= 1) buckets.正常++
    else if (a.severity === 2) buckets.预警++
    else if (a.severity === 3) buckets.告警++
    else buckets.严重++
  }
  donutChart.setOption({
    backgroundColor: 'transparent',
    tooltip: { trigger: 'item' },
    series: [{
      type: 'pie',
      radius: ['55%', '80%'],
      label: { color: '#cfe8ff' },
      data: [
        { name: '正常', value: buckets.正常, itemStyle: { color: '#2cf3ff' } },
        { name: '预警', value: buckets.预警, itemStyle: { color: '#50e3c2' } },
        { name: '告警', value: buckets.告警, itemStyle: { color: '#f5a623' } },
        { name: '严重', value: buckets.严重, itemStyle: { color: '#ff4d4f' } }
      ]
    }]
  })
}

function renderBarChart() {
  if (!barEl.value) return
  if (!barChart) {
    barChart = echarts.init(barEl.value)
    window.addEventListener('resize', () => barChart && barChart.resize())
  }
  const categories = ['Cylinder', 'Torque', 'Speed']
  const counts = [chartLastData.value.length, torqueData.value.length, speedData.value.length]
  barChart.setOption({
    backgroundColor: 'transparent',
    grid: { left: 40, right: 10, top: 20, bottom: 20 },
    xAxis: { type: 'category', data: categories, axisLabel: { color: '#cfe8ff' }, axisLine: { lineStyle: { color: '#6ea1c5' } } },
    yAxis: { type: 'value', axisLabel: { color: '#cfe8ff' }, axisLine: { lineStyle: { color: '#6ea1c5' } }, splitLine: { lineStyle: { color: '#1a3b5a' } } },
    series: [{ type: 'bar', data: counts, itemStyle: { color: '#2cf3ff' } }]
  })
}

function renderTrendChart() {
  if (!trendEl.value) return
  if (!trendChart) {
    trendChart = echarts.init(trendEl.value)
    window.addEventListener('resize', () => trendChart && trendChart.resize())
  }
  const data = chartLastData.value
  if (!data.length) { trendChart.clear(); return }
  const points = data.slice(-20)
  const xs = points.map(p => new Date(p.timestampUtc).toLocaleTimeString())
  const ys = points.map(p => p.value)
  trendChart.setOption({
    backgroundColor: 'transparent',
    grid: { left: 30, right: 10, top: 20, bottom: 25 },
    xAxis: { type: 'category', data: xs, axisLabel: { color: '#cfe8ff' }, axisLine: { lineStyle: { color: '#6ea1c5' } } },
    yAxis: { type: 'value', axisLabel: { color: '#cfe8ff' }, axisLine: { lineStyle: { color: '#6ea1c5' } }, splitLine: { lineStyle: { color: '#1a3b5a' } } },
    series: [{ type: 'line', data: ys, smooth: true, lineStyle: { color: '#50e3c2' } }]
  })
}

async function createRule() {
  if (!selectedDeviceId.value) return
  const payload = { deviceId: selectedDeviceId.value, metric: metric.value, operator: 5, minValue: 10, maxValue: 80, enabled: true, severity: 2 }
  await axios.post(`${apiBase.value}/api/thresholds`, payload)
  await fetchRules()
}

function setupHub() {
  const connection = new signalR.HubConnectionBuilder()
    .withUrl(`${hubBase.value}/hubs/alerts`)
    .withAutomaticReconnect()
    .build()
  connection.on('alerts', (incoming: Alert[]) => {
    alerts.value = [...incoming, ...alerts.value].slice(0, 200)
  })
  connection.start().catch(console.error)
}

// 存储轴历史数据用于趋势图
const axisHistoryData = ref<Record<string, Array<{time: number, torque: number, speed: number}>>>({})

function renderTrendChartsView() {
  if (!trendChartsEl.value) return
  if (!trendChartsChart) {
    trendChartsChart = echarts.init(trendChartsEl.value)
    window.addEventListener('resize', () => trendChartsChart && trendChartsChart.resize())
  }
  
  // 为每个轴收集历史数据用于趋势图显示
  updateAxisHistoryData()
  
  // 选择几个主要轴进行趋势显示，避免图表过于拥挤
  const selectedAxes = ['主轴A1', '主轴B1', '辅助轴D1', '进给轴X', '回转轴A', '驱动轴M1']
  const colors = ['#2cf3ff', '#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#ffa726']
  
  const series: any[] = []
  
  selectedAxes.forEach((axisName, index) => {
    const history = axisHistoryData.value[axisName] || []
    
    // 扭矩趋势线
    series.push({
      name: `${axisName}-扭矩`,
      type: 'line',
      smooth: false, // 直线，不平滑
      showSymbol: true,
      symbolSize: 3,
      lineStyle: { width: 1.5, color: colors[index], type: 'solid' },
      data: history.map(h => [h.time, h.torque])
    })
    
    // 速度趋势线
    series.push({
      name: `${axisName}-速度`,
      type: 'line',
      smooth: false, // 直线，不平滑
      showSymbol: true,
      symbolSize: 3,
      lineStyle: { width: 1.5, color: colors[index], type: 'dashed' },
      data: history.map(h => [h.time, h.speed])
    })
  })
  
  trendChartsChart.setOption({
    backgroundColor: 'transparent',
    tooltip: { 
      trigger: 'axis',
      axisPointer: { type: 'cross' },
      formatter: function(params: any) {
        let content = `时间: ${new Date(params[0].value[0]).toLocaleTimeString()}<br/>`
        params.forEach((param: any) => {
          content += `${param.seriesName}: ${param.value[1]}<br/>`
        })
        return content
      }
    },
    legend: { 
      data: series.map(s => s.name),
      textStyle: { color: '#93dcfe', fontSize: 10 },
      top: 5,
      type: 'scroll'
    },
    grid: { left: 50, right: 20, top: 40, bottom: 40 },
    xAxis: { 
      type: 'time',
      axisLine: { lineStyle: { color: '#6ea1c5' } },
      axisLabel: { color: '#cfe8ff', fontSize: 10 },
      splitLine: { show: false }
    },
    yAxis: { 
      type: 'value',
      axisLine: { lineStyle: { color: '#6ea1c5' } },
      axisLabel: { color: '#cfe8ff', fontSize: 10 },
      splitLine: { lineStyle: { color: '#1a3b5a', width: 0.5 } }
    },
    series: series
  })
}

function updateCylinderStrokeData() {
  // 模拟气缸行程时间数据
  const cylinderNames = [
    '气缸#1', '气缸#2', '气缸#3', '气缸#4', '气缸#5', '气缸#6',
    '气缸#7', '气缸#8', '气缸#9', '气缸#10', '气缸#11', '气缸#12'
  ]
  const now = new Date()
  const statuses = ['正常', '警告', '正常', '正常', '异常']
  
  cylinderStrokeData.value = cylinderNames.map((cylinderName, index) => {
    // 模拟行程时间: 0.5-2.5秒
    const baseStrokeTime = 1.0 + (index % 3) * 0.3
    const simulatedStrokeTime = baseStrokeTime + Math.sin(Date.now() / 2000 + index) * 0.2 + Math.random() * 0.1
    
    return {
      cylinderName,
      time: new Date(now.getTime() - (index * 800) - Math.random() * 1500).toLocaleTimeString(),
      strokeTime: Math.max(0.1, simulatedStrokeTime).toFixed(2) + 's',
      status: statuses[index % statuses.length] || '正常'
    }
  })
}

function updateAxisHistoryData() {
  const now = Date.now()
  const maxHistoryPoints = 30 // 保持30个历史点，显示更密集的数据
  
  realtimeAxisData.value.forEach(axis => {
    if (!axisHistoryData.value[axis.axisName]) {
      axisHistoryData.value[axis.axisName] = []
    }
    
    const history = axisHistoryData.value[axis.axisName]
    if (history) {
      // 添加新数据点
      history.push({
        time: now,
        torque: parseFloat(axis.torque),
        speed: parseFloat(axis.speed)
      })
      
      // 保持历史数据点数量
      if (history.length > maxHistoryPoints) {
        history.shift()
      }
    }
  })
}

const alertBoardConfig = computed(() => ({
  header: ['时间', '告警', '级别'],
  data: alerts.value.map(a => [new Date(a.createdUtc).toLocaleString(), a.message, `S${a.severity}`]),
  rowNum: 10,
  index: true,
  hoverPause: true
}))

watch([selectedDeviceId, metric], async () => {
  await fetchRules()
  await refreshCharts()
  await refreshSideSeries()
})

onMounted(async () => {
  await fetchDevices()
  await fetchRules()
  await refreshCharts()
  await refreshSideSeries()
  setupHub()
  // render side charts initially and on alert updates
  renderDonutChart()
  renderBarChart()
  
  // 设置定时器定期更新轴数据，模拟从SQL Server实时读取
  setInterval(() => {
    updateRealtimeAxisData()
    updateCylinderStrokeData()
    renderTrendChartsView() // 同时更新趋势图
  }, 3000) // 每3秒更新一次
})
</script>

<template>
  <div style="height:100vh; width:100vw; color:#cfe8ff; display:flex; flex-direction:column; overflow:hidden; background:#0a1f37; position:fixed; top:0; left:0; right:0; bottom:0; z-index:1000;">
    <div style="height:100%; width:100%; display:flex; flex-direction:column;">
      <!-- Top Header -->
      <div style="height:80px; position:relative; display:flex; align-items:center; justify-content:center; background:linear-gradient(90deg, #0a1f37, #1a4b73);">
        <dv-decoration-5 style="position:absolute; top:0; left:0; width:100%; height:100%; z-index:1;" />
        <div class="main-title" style="font-weight:600; color:#cfe8ff; z-index:10; position:relative; margin-top:-16px;">预测性维护 · 大屏监控</div>
        <!-- Navigation Pills in Top Header -->
        <div style="position:absolute; bottom:16px; left:12px; display:flex; align-items:center; z-index:10;">
          <div class="nav-pill active">数据总览</div>
          <div class="nav-pill">PM看板</div>
          <div class="nav-pill">设备中心</div>
          <div class="nav-pill">工单管理</div>
        </div>
        <!-- Control Panel in Top Header -->
        <div style="position:absolute; bottom:16px; right:12px; display:flex; gap:4px; font-size:11px; align-items:center; z-index:10;">
          <span style="color:#93dcfe;">API</span>
          <input v-model="apiBase" style="width:160px; height:20px; background:#0a2c4a; border:1px solid #2c7fb8; color:#cfe8ff; padding:1px 4px; font-size:10px;" />
          <span style="color:#93dcfe;">设备</span>
          <select v-model="selectedDeviceId" style="height:20px; background:#0a2c4a; border:1px solid #2c7fb8; color:#cfe8ff; padding:1px 3px; font-size:10px;">
            <option v-for="d in devices" :key="d.id" :value="d.id">{{ d.name }}</option>
          </select>
          <span style="color:#93dcfe;">指标</span>
          <select v-model.number="metric" style="height:20px; background:#0a2c4a; border:1px solid #2c7fb8; color:#cfe8ff; padding:1px 3px; font-size:10px;">
            <option :value="1">CylinderStrokeTime</option>
            <option :value="2">ShaftTorque</option>
            <option :value="3">Speed</option>
          </select>
          <button @click="createRule" style="height:20px; background:#2c7fb8; color:#fff; border:none; padding:0 6px; font-size:10px;">快速阈值</button>
        </div>
      </div>

      <!-- Main Content Grid -->
      <div style="flex:1; display:grid; grid-template-columns: 600px 1fr 600px; gap:8px; padding:8px 8px 4px 8px; min-height:0; overflow:hidden;">
        
        <!-- Left Column -->
        <div style="display:flex; flex-direction:column; gap:8px;">
          <!-- KPI Cards - With Border Effects -->
          <div style="display:flex; gap:8px;">
            <dv-border-box-1 style="flex:1; height:80px; padding:4px;">
              <div class="kpi-card">
                <div class="kpi-title">平均行程</div>
                <div class="kpi-value">{{ kpiStrokeAvg.toFixed(2) }}</div>
              </div>
            </dv-border-box-1>
            <dv-border-box-1 style="flex:1; height:80px; padding:4px;">
              <div class="kpi-card">
                <div class="kpi-title">平均扭矩</div>
                <div class="kpi-value">{{ kpiTorqueAvg.toFixed(2) }}</div>
              </div>
            </dv-border-box-1>
            <dv-border-box-1 style="flex:1; height:80px; padding:4px;">
              <div class="kpi-card">
                <div class="kpi-title">平均速度</div>
                <div class="kpi-value">{{ kpiSpeedAvg.toFixed(2) }}</div>
              </div>
            </dv-border-box-1>
          </div>

          <!-- Data Monitoring Section -->
          <dv-border-box-1 style="flex:1; min-height:150px;">
            <div style="height:100%; display:flex; flex-direction:column;">
              <!-- Upper Section - Axis Real-time Data -->
              <div style="flex:1; display:flex; flex-direction:column;">
                <div class="panel-header">轴实时数据监控</div>
                <div style="flex:1; overflow:auto; padding:11px;">
                  <table class="data-table">
                    <thead>
                      <tr>
                        <th>轴名称</th>
                        <th>时间</th>
                        <th>扭矩</th>
                        <th>速度</th>
                        <th>状态</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(item, index) in realtimeAxisData.slice(0, 10)" :key="index">
                        <td>{{ item.axisName }}</td>
                        <td>{{ item.time }}</td>
                        <td>{{ item.torque }}</td>
                        <td>{{ item.speed }}</td>
                        <td>
                          <span :class="item.status === '警告' ? 'status-warning' : 'status-normal'">
                            {{ item.status }}
                          </span>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
              
              <!-- Lower Section - Cylinder Stroke Time -->
              <div style="flex:1; display:flex; flex-direction:column;">
                <div class="panel-header">气缸行程时间</div>
                <div style="flex:1; overflow:auto; padding:11px;">
                  <table class="data-table">
                    <thead>
                      <tr>
                        <th>气缸编号</th>
                        <th>时间</th>
                        <th>行程时间</th>
                        <th>状态</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(item, index) in cylinderStrokeData" :key="index">
                        <td>{{ item.cylinderName }}</td>
                        <td>{{ item.time }}</td>
                        <td>{{ item.strokeTime }}</td>
                        <td>
                          <span :class="item.status === '警告' ? 'status-warning' : item.status === '异常' ? 'status-warning' : 'status-normal'">
                            {{ item.status }}
                          </span>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </dv-border-box-1>
        </div>

        <!-- Center Column -->
        <div style="display:flex; flex-direction:column; gap:8px;">
          <!-- Upper Section - Placeholder -->
          <dv-border-box-1 style="flex:1; display:flex; align-items:center; justify-content:center; min-height:180px;">
            <div style="font-size:32px; font-weight:600; color:#93dcfe; text-align:center;">
              暂定
            </div>
          </dv-border-box-1>

          <!-- Lower Section - Data Collection Trend Charts -->
          <dv-border-box-1 style="flex:1; min-height:200px;">
            <div style="height:100%; display:flex; flex-direction:column;">
              <div class="panel-header">轴实时数据趋势图</div>
              <div ref="trendChartsEl" style="flex:1; width:100%;"></div>
            </div>
          </dv-border-box-1>
        </div>

        <!-- Right Column -->
        <div style="display:flex; flex-direction:column; gap:8px;">
          <!-- Realtime Alerts -->
          <dv-border-box-1 style="height:200px; display:flex; flex-direction:column;">
            <div class="panel-header">Realtime Alerts</div>
            <div style="flex:1; padding:11px;">
              <dv-scroll-board :config="alertBoardConfig" style="width:100%; height:100%;" />
            </div>
          </dv-border-box-1>

          <!-- Stats Charts -->
          <dv-border-box-1 style="height:180px; display:flex; flex-direction:column;">
            <div class="panel-header">完成占比 / 时间数据</div>
            <div style="flex:1; display:flex; gap:8px; padding:11px;">
              <div ref="donutEl" style="flex:1;"></div>
              <div ref="barEl" style="flex:1;"></div>
            </div>
          </dv-border-box-1>

          <!-- Trend Preview -->
          <dv-border-box-1 style="height:140px; display:flex; flex-direction:column;">
            <div class="panel-header">趋势预览</div>
            <div ref="trendEl" style="flex:1; width:100%;"></div>
          </dv-border-box-1>

          <!-- Threshold Rules -->
          <dv-border-box-1 style="flex:1; display:flex; flex-direction:column;">
            <div class="panel-header">Threshold Rules</div>
            <div style="flex:1; overflow:auto; padding:11px;">
              <table class="data-table">
                <thead><tr><th>Metric</th><th>Op</th><th>Min</th><th>Max</th><th>En</th><th>Sev</th></tr></thead>
                <tbody>
                  <tr v-for="r in rules" :key="r.id">
                    <td>{{ r.metric }}</td><td>{{ r.operator }}</td><td>{{ r.minValue }}</td>
                    <td>{{ r.maxValue }}</td><td>{{ r.enabled }}</td><td>{{ r.severity }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </dv-border-box-1>
        </div>

      </div>
    </div>
  </div>
</template>

<style scoped>
.nav-pill {
  padding: 3px 8px;
  margin-right: 6px;
  font-size: 11px;
  color: #93dcfe;
  border: 1px solid #2c7fb8;
  background: transparent;
  cursor: pointer;
  font-family: 'Microsoft YaHei', '微软雅黑', Arial, sans-serif;
  height: 20px;
  display: flex;
  align-items: center;
}
.nav-pill.active {
  background: #2c7fb8;
  color: #fff;
}

.panel-header {
  padding: 8px 12px;
  font-size: 14px;
  font-weight: 600;
  color: #93dcfe;
  border-bottom: 1px solid #2c7fb8;
}

.kpi-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 4px;
  height: 100%;
  width: 100%;
  padding: 0;
  margin: 0;
}
.kpi-title {
  font-size: 10px;
  color: #93dcfe;
  margin-bottom: 6px;
  text-align: center;
  width: 100%;
  line-height: 1.2;
}
.kpi-value {
  font-size: 18px;
  font-weight: 700;
  color: #2cf3ff;
  text-align: center;
  width: 100%;
  line-height: 1;
  margin: 0;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  color: #cfe8ff;
  font-size: 11px;
}
.data-table th,
.data-table td {
  padding: 3px 6px;
  border-bottom: 1px solid #2c7fb8;
  text-align: left;
}
.data-table thead th {
  background: rgba(44, 127, 184, 0.3);
  position: sticky;
  top: 0;
  font-weight: 600;
}
.data-table tbody tr:hover {
  background: rgba(44, 243, 255, 0.05);
}

/* 响应式主标题 */
.main-title {
  font-size: clamp(24px, 4vw, 48px);
}

/* 响应式适配不同分辨率 */
@media screen and (min-width: 2560px) {
  .main-title { font-size: 52px; }
}

@media screen and (min-width: 1920px) and (max-width: 2559px) {
  .main-title { font-size: 45px; }
}

@media screen and (min-width: 1600px) and (max-width: 1919px) {
  .main-title { font-size: 42px; }
}

@media screen and (min-width: 1366px) and (max-width: 1599px) {
  .main-title { font-size: 38px; }
}

@media screen and (max-width: 1365px) {
  .main-title { font-size: 32px; }
}

/* 输入框和控件样式 - 紧凑版本 */
input, select {
  background: #0a2c4a !important;
  border: 1px solid #2c7fb8 !important;
  color: #cfe8ff !important;
  padding: 2px 6px !important;
  font-size: 11px !important;
}

button {
  background: #2c7fb8 !important;
  color: #fff !important;
  border: none !important;
  padding: 0 8px !important;
  font-size: 11px !important;
  height: 24px !important;
}

/* 全局字体美化 */
* {
  font-family: 'Microsoft YaHei', '微软雅黑', 'PingFang SC', 'Helvetica Neue', Arial, sans-serif;
}

/* 状态颜色样式 */
.status-normal {
  color: #00ff88 !important;
  font-weight: 600;
  text-shadow: 0 0 4px rgba(0, 255, 136, 0.4);
}

.status-warning {
  color: #ff4757 !important;
  font-weight: 600;
  text-shadow: 0 0 4px rgba(255, 71, 87, 0.4);
  animation: pulse-warning 2s infinite;
}

@keyframes pulse-warning {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

/* 确保全屏无滚动 */
@media screen and (max-height: 720px) {
  .kpi-card { min-height: 50px; }
  .panel-header { padding: 4px 8px; font-size: 11px; }
}
</style>
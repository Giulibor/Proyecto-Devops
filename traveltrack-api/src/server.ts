import express from 'express'
import helmet from 'helmet'
import morgan from 'morgan'
import cors from 'cors'
import travelRequests from './routes/travelRequests'
import { loadEnv } from './config'

const env = loadEnv()
const app = express()

app.use(helmet())
app.use(cors())
app.use(express.json())
app.use(morgan('combined'))

// Health
app.get('/health', (_req, res) => {
  res.json({ status: 'ok' })
})

// Version (desde variable de entorno / ConfigMap)
app.get('/api/version', (_req, res) => {
  res.json({ version: env.APP_VERSION })
})

// Travel Requests API
app.use(travelRequests)

// 404
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' })
})

// Error handler básico
// eslint-disable-next-line @typescript-eslint/no-misused-promises
app.use(async (err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err)
  res.status(500).json({ error: 'Internal Server Error' })
})

const port = Number(env.PORT)
app.listen(port, () => {
  console.log(`🚀 TravelTrack API listening on :${port} (env=${env.NODE_ENV})`)
})

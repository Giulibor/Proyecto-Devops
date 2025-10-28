import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().default('8080'),
  APP_VERSION: z.string().default('0.0.0')
})

export type Env = z.infer<typeof envSchema>

export function loadEnv (): Env {
  // No usamos dotenv por defecto; Kubernetes/Helm inyectarán variables.
  // Para desarrollo local se puede usar `export VAR=value` o agregar dotenv si se desea.
  const parsed = envSchema.safeParse(process.env)
  if (!parsed.success) {
    console.error('❌ Invalid environment variables:', parsed.error.format())
    process.exit(1)
  }
  return parsed.data
}

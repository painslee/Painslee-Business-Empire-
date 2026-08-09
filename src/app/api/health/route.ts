import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { supabaseUrl, supabaseAnonKey } from '@/lib/supabase/client'

interface HealthResponse {
  status: 'healthy' | 'degraded'
  timestamp: string
  version: string
  application: {
    running: boolean
  }
  supabase: {
    status: 'CONFIGURED' | 'NOT_CONFIGURED' | 'UNAVAILABLE'
    url_set: boolean
    key_set: boolean
  }
}

export async function GET(_request: NextRequest): Promise<NextResponse<HealthResponse>> {
  const timestamp = new Date().toISOString()

  // Check if Supabase environment variables are set
  const urlSet = !!supabaseUrl
  const keySet = !!supabaseAnonKey

  let supabaseStatus: 'CONFIGURED' | 'NOT_CONFIGURED' | 'UNAVAILABLE' = 'NOT_CONFIGURED'

  // If not configured, report as NOT_CONFIGURED
  if (!urlSet || !keySet) {
    supabaseStatus = 'NOT_CONFIGURED'
  } else {
    // Try to verify connection by making a simple request
    try {
      const response = await fetch(`${supabaseUrl}/rest/v1/`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${supabaseAnonKey}`,
          'apikey': supabaseAnonKey,
        },
        timeout: 5000,
      })

      // If we get any response, connection is possible
      if (response.ok || response.status === 401 || response.status === 404) {
        supabaseStatus = 'CONFIGURED'
      } else {
        supabaseStatus = 'UNAVAILABLE'
      }
    } catch (_error) {
      // Network error or timeout
      supabaseStatus = 'UNAVAILABLE'
    }
  }

  // Determine overall health
  const isHealthy = supabaseStatus === 'CONFIGURED'

  const healthResponse: HealthResponse = {
    status: isHealthy ? 'healthy' : 'degraded',
    timestamp,
    version: '1.3.0',
    application: {
      running: true,
    },
    supabase: {
      status: supabaseStatus,
      url_set: urlSet,
      key_set: keySet,
    },
  }

  const statusCode = isHealthy ? 200 : 503

  return NextResponse.json(healthResponse, { status: statusCode })
}

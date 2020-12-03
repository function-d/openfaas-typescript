type Query = { 
    [key: string] : string | number | query 
}

type FunctionEvent = {
    body: any
    headers: { [key: string] : string }
    method: 'all' | 'get' | 'post' | 'put' | 'delete' | 'patch' | 'options' | 'head'
    path: string
    query: Query
}

type FunctionContext = { 
    headers: (headers: Record<string,string>) => FunctionContext
    headers: () => Record<string,string>
    status: (status: number) => FunctionContext
    status: () => number
    succeed: (ResBody?: any) => void
    failed: (ResBody?: any) => void
}
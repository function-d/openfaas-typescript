export default function(event: FunctionEvent , context: FunctionContext) {
    const result = {
        'status': 'Received input: ' + JSON.stringify(event.body)
      }
    
      return context
        .headers({
            'text': '123'
        })
        .status(200)
        .succeed(result)
}
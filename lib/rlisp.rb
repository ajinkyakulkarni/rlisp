class Rlisp
  OPERATORS = %i[== != < <= > >= + - * /]

  def initialize(ext = {})
    @env = {
      :min   => lambda { |*list| list.min },
      :max   => lambda { |*list| list.max },
      :car   => lambda { |*list| list[0] },
      :cdr   => lambda { |*list| list.drop 1 },
      :cons  => lambda { |(e, cell), _| [e] + cell },
      :eq?   => lambda { |(l, r), ctx| eval(l, ctx) == eval(r, ctx) },
    }.merge(ext)

    OPERATORS.inject({}) do |scope, operator|
      @env.merge!(operator => lambda { |*args| args.inject(&operator) })
    end
  end

  def run(code)
    self.eval parse(code)
  end

  def parse(program)
    read_from_tokens(tokenize(program))
  end

  def tokenize(chars)
    chars.gsub('(', ' ( ').gsub(')', ' ) ').split(' ')
  end

  def read_from_tokens(tokens)
    return if tokens.empty?

    token = tokens.shift

    if '(' == token
      list = []

      while tokens.first != ')'
        list << read_from_tokens(tokens)
      end
      tokens.shift

      list
    elsif ')' == token
      raise 'unexpected )'
    else
      atom(token)
    end
  end

  def atom(token)
    if token[/\.\d+/]
      token.to_f
    elsif token[/\d+/]
      token.to_i
    else
      token.to_sym
    end
  end

  def eval(exp, env = @env)
    if exp.is_a? Numeric
      exp
    elsif exp.is_a? Symbol
      env[exp]
    elsif exp[0] == :quote
      exp[1..-1]
    elsif exp[0] == :if
      _, test, conseq, alt = exp
      exp = eval(test, env) ? conseq : alt
      eval(exp, env)
    elsif exp[0] == :define
      _, var, e = exp
      env[var] = eval(e, env)
    elsif exp[0] == :lambda
      _, params, e = exp
      lambda { |*args| self.eval(e, env.merge(Hash[params.zip(args)])) }
    else
      code = eval(exp[0], env)
      args = exp[1..-1].map{ |arg| eval(arg, env) }
      code.(*args)
    end
  end
end

rlisp = Rlisp.new
p rlisp.run("(define r 10)")
p rlisp.run("(define pi 3.14)")
p rlisp.run("(* pi (* r r))")

p rlisp.run("(define circle-area (lambda (r) (* pi (* r r))))")
p rlisp.run("(circle-area 11)")
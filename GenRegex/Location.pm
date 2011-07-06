package Location;

sub new {
    my $class = shift;
    my $self = {};

    $self->{name} = shift;
    $self->{regex} = shift;
    $self->{start} = shift;
    $self->{end} = shift;

    bless ($self, $class);
    return $self;
}

sub getName {
    my $self = shift;
    return $self->{name};
}

sub getRegex {
    my $self = shift;
    return $self->{regex};
}

sub getStart {
    my $self = shift;
    return $self->{start};
}

sub getEnd {
    my $self = shift;
    return $self->{end};
}

sub toString () {
    my $self = shift;
    return "$self->{name}:$self->{regex}:$self->{start}:$self->{end}";
}

1;

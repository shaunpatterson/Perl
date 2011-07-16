package Location;

sub new {
    my $class = shift;
    my $self = {};

    $self->{name} = shift;
    $self->{regex} = shift;
    $self->{match} = shift;
    $self->{start} = shift;
    $self->{end} = shift;

    # Index in a match array, used by the view to easily pick out user selections
    $self->{index} = -1;

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

sub getMatch {
    my $self = shift;
    return $self->{match};
}

sub getStart {
    my $self = shift;
    return $self->{start};
}

sub getEnd {
    my $self = shift;
    return $self->{end};
}

sub setIndex () {
    my ($self, $newIndex) = @_;
    $self->{index} = $newIndex;
}

sub getIndex () {
    my $self = shift;
    return $self->{index};
}

sub toString () {
    my $self = shift;
    return "$self->{name}:$self->{regex}:$self->{match}:$self->{start}:$self->{end}:$self->{index}";
}



1;

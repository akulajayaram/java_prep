import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

public class Streams {
    public static void main(String[] args){
        List<Employee> empList = new ArrayList<>();
        empList.add(new Employee(1, "Yanksha", 28, 123, "F", "HR", "Blore", 2020));
        empList.add(new Employee(2, "Francesca", 29, 120, "F", "HR", "Hyderabad", 2015));
        empList.add(new Employee(3, "Ramesh", 30, 115, "M", "HR", "Chennai", 2014));
        empList.add(new Employee(4, "Melanie", 32, 125, "F", "HR", "Chennai", 2013));

        empList.add(new Employee(5, "Padma", 22, 150, "F", "IT", "Noida", 2013));
        empList.add(new Employee(6, "Milad", 27, 140, "M", "IT", "Gurugram", 2017));
        empList.add(new Employee(7, "Uzma", 26, 130, "F", "IT", "Pune", 2016));
        empList.add(new Employee(8, "Ali", 23, 145, "M", "IT", "Trivandam", 2015));
        empList.add(new Employee(9, "Ram", 25, 160, "M", "IT", "Blore", 2010));



        // 1. Group the employees by a single field, like city or age
        Map<String,List<Employee>> byCity = empList.stream().collect(Collectors.groupingBy(Employee::getCity));
        Map<Integer,List<Employee>> byAge = empList.stream().collect(Collectors.groupingBy(Employee::getAge));

        // 2. Find the count of male and female employees present in the organization.
        Map<String, Long> byGenderCount = empList.stream().collect(Collectors.groupingBy(Employee::getGender, Collectors.counting()));

        // 3. Find the count of male and female present in each department
        Map<String, Map<String, Long>> byDepartmentGenderCount = empList.stream().collect(Collectors.groupingBy(Employee::getDeptName,Collectors.groupingBy(Employee::getGender,Collectors.counting())));

        // 4. Find the names of all distinct departments in the organization.
        List<String> byDistictDepartments = empList.stream().map(Employee::getDeptName).distinct().collect(Collectors.toList());

        // 5. Find employee details whose age is greater than 28 in the organisation.
        List<Employee> byageGreaterthan28 = empList.stream().filter(e->e.age > 28).toList();

        // 6. Find maximum age/oldest of employee in the organisation.
        Optional<Employee> oldestEmp1 = empList.stream().max(Comparator.comparing(Employee::getAge));
        OptionalInt oldestEmp2 = empList.stream().mapToInt(Employee::getAge).max();
        Optional<Integer> oldestEmp3 = empList.stream().map(Employee::getAge).max(Integer::compareTo);

        // 7. Print Average age of Male and Female Employees in the organisation.
        Map<String, Double> byAvgMFemp = empList.stream().collect(Collectors.groupingBy(Employee::getGender,Collectors.averagingInt(Employee::getAge)));

        // 8. Print Average age of Male and Female Employees in each department.
        Map<String,Map<String,Double>> byAvgMFbyDept= empList.stream().collect(Collectors.groupingBy(Employee::getDeptName,Collectors.groupingBy(Employee::getGender,Collectors.averagingInt(Employee::getAge))));
        //  byAvgMFbyDept.forEach((dept,ageMap)->ageMap.forEach((g,avg)-> System.out.println(dept + "-->" +g+"  "+avg)));

        // 9. Print the number of employees in each department.
        Map<String,Long> byDeptCount = empList.stream().collect(Collectors.groupingBy(Employee::getDeptName, Collectors.counting()));

        // 10. Find the longest-serving employees in the organization
        Optional<Employee> longestServEmp = empList.stream().sorted(Comparator.comparingInt(Employee::getYearOfJoining)).findFirst();

        // * 11. Find the longest-serving employee in each department
        Map<String, Optional<Employee>> longServEmpDept = empList.stream().collect(Collectors.groupingBy(Employee::getDeptName, Collectors.minBy(Comparator.comparing(Employee::getYearOfJoining))));

        // 12. Find youngest female employee in the organisation.
        Optional<Employee> youngEmp = empList.stream().filter(e->e.gender =="F").min(Comparator.comparing(Employee::getAge));

        //* 13. Find the department name that has the highest number of employees
        String byHighEmpDept = empList.stream()
                .collect(Collectors.groupingBy(Employee::getDeptName, Collectors.counting()))
                .entrySet().stream()
                .max(Comparator.comparing(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElse("No Department");

        //* 14. Sorting a Stream by age and name fields.
        Comparator<Employee> comparator1 = Comparator.comparing(e->e.name);
        Comparator<Employee> comparator2 = Comparator.comparing(e->e.age);
        List<Employee> sortByNameAge = empList.stream().sorted(comparator1.thenComparing(comparator2)).toList();

        // 15. Print average and total salary of the organization.
        DoubleSummaryStatistics empStats = empList.stream().mapToDouble(e->e.salary).summaryStatistics();
        //   System.out.println(empStats.getAverage()+" , "+ empStats.getSum());

        // 16. Print Average salary by gender in each department
        Map<String,Map<String,Double>> avgSalbyGenderDept = empList.stream()
                .collect(Collectors.groupingBy(e->e.deptName, Collectors.groupingBy(e->e.gender, Collectors.averagingDouble(e->e.salary))));

        // 17. Find Highest salary in the organisation.
        Optional<Employee> highestSalEmp = empList.stream().max(Comparator.comparing(e->e.salary));
        Optional<Employee> highestSalEmp2= empList.stream().sorted((Comparator.comparingDouble((Employee e)->e.salary)).reversed()).findFirst();

        // 18. Find Second Highest salary in the organisation.
        Optional<Employee> secondHighSalEmp= empList.stream().sorted((Comparator.comparingDouble((Employee e)->e.salary)).reversed()).skip(1).findFirst();

        // 19. Nth Highest salary. n=3
        int n=3;
        Optional<Employee> nthHighSalEmp = empList.stream().sorted((Comparator.comparingDouble((Employee e)->e.salary)).reversed()).skip(n-1).findFirst();

        // 20. Print the top 3 highest-salaried employees in the organisation
        empList.stream().sorted(Comparator.comparingDouble((Employee e)-> e.salary).reversed()).limit(3).forEach(e -> System.out.println("Top earner: " + e.name + " – ₹" + e.salary));

        // 21. Find the first non-repeating character in a string
        // Approach 1
        String str= "oiuytrfghjklpoikmnbvcdwqasdxcftyhbhjikmlop";
        Optional<Character> firstNonRepeat = str.chars()
                .mapToObj(c -> (char) c)
                .collect(Collectors.groupingBy(
                        Function.identity(),
                        LinkedHashMap::new, // Ensures insertion order is preserved
                        Collectors.counting()
                ))
                .entrySet().stream()
                .filter(entry -> entry.getValue() == 1L) // Filter for count of 1
                .map(Map.Entry::getKey) // Get the character
                .findFirst(); // Retrieve the first one in order
        // Approach 2
        int[] counts = new int[256]; // Assumes extended ASCII. Use 65536 for full basic UTF-16.
        str.chars().forEach(c -> counts[c]++);
        str.chars()
                .filter(c -> counts[c] == 1)
                .mapToObj(c -> (char) c)
                .findFirst();

        // 22. Find first non repeating string in array
        String[] input = {"apple", "banana", "apple", "cherry", "banana", "date"};
        List<String> inputStr = new ArrayList<>(Arrays.asList(input));

        String result= inputStr.stream().collect(Collectors.groupingBy(st->st,LinkedHashMap::new,Collectors.counting()))
                .entrySet().stream()
                .filter(entry->entry.getValue() ==1)
                .map(entry->entry.getKey()).findFirst().orElse(null);

        // 23. count the total number of distinct words (case-insensitive) in all the sentences
        List<String> sentences = Arrays.asList(
                "Java Stream API provides a fluent interface for processing sequences of elements.",
                "It supports functional-style operations on streams of elements, such as map-reduce transformations.",
                "In this exercise, you need to count the total number of words in all sentences."
        );

        long result1 = sentences.stream()
                .flatMap(s -> Arrays.stream(s.trim().split("\\s+")))
                .map(String::toLowerCase)
                .distinct()
                .count();

        // 24. find the concatenation of the first two words that have even lengths.
        List<String> words = Arrays.asList("apple", "banana", "cherry", "date", "elderberry");


        // 25. find the sum of the squares of even numbers in the list
        List<Integer> numbers = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);



        System.out.println(result);
    }
    static class  Employee {
        private int id;
        private String name;
        private int age;
        private long salary;
        private String gender;
        private String deptName;
        private String city;
        private int yearOfJoining;

        public Employee(int id, String name, int age, long salary, String gender,
                        String deptName, String city, int yearOfJoining) {
            this.id = id;
            this.name = name;
            this.age = age;
            this.salary = salary;
            this.gender = gender;
            this.deptName = deptName;
            this.city = city;
            this.yearOfJoining = yearOfJoining;
        }

        @Override
        public String toString() {
            return "Employee{" +
                    "id=" + id +
                    ", name='" + name + '\'' +
                    ", age=" + age +
                    ", salary=" + salary +
                    ", gender='" + gender + '\'' +
                    ", deptName='" + deptName + '\'' +
                    ", city='" + city + '\'' +
                    ", yearOfJoining='" + yearOfJoining + '\'' +
                    '}';
        }

        public int getId() {
            return id;
        }

        public void setId(int id) {
            this.id = id;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public int getAge() {
            return age;
        }

        public void setAge(int age) {
            this.age = age;
        }

        public long getSalary() {
            return salary;
        }

        public void setSalary(long salary) {
            this.salary = salary;
        }

        public String getGender() {
            return gender;
        }

        public void setGender(String gender) {
            this.gender = gender;
        }

        public String getDeptName() {
            return deptName;
        }

        public void setDeptName(String deptName) {
            this.deptName = deptName;
        }

        public String getCity() {
            return city;
        }

        public void setCity(String city) {
            this.city = city;
        }

        public int getYearOfJoining() {
            return yearOfJoining;
        }

        public void setYearOfJoining(int yearOfJoining) {
            this.yearOfJoining = yearOfJoining;
        }
    }
}
